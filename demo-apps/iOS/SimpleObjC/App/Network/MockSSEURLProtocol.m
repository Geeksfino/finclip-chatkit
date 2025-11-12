//
//  MockSSEURLProtocol.m
//  SimpleChatObjC
//
//  URLProtocol that replays AG-UI events as a Server-Sent Events (SSE) stream
//

#import "MockSSEURLProtocol.h"

@interface MockSSEURLProtocol ()

@property (nonatomic, class, readonly) dispatch_queue_t queue;
@property (nonatomic, class) NSArray<NSData *> *events;
@property (nonatomic, class) NSTimeInterval interval;
@property (nonatomic, class, nullable) void(^completionHandler)(void);
@property (nonatomic, class) BOOL echoMode;

@end

@implementation MockSSEURLProtocol

static dispatch_queue_t _queue = nil;
static NSArray<NSData *> *_events = nil;
static NSTimeInterval _interval = 0.2;
static void(^_completionHandler)(void) = nil;
static BOOL _echoMode = NO;

+ (dispatch_queue_t)queue {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _queue = dispatch_queue_create("MockSSEURLProtocol.queue", DISPATCH_QUEUE_SERIAL);
    });
    return _queue;
}

+ (NSArray<NSData *> *)events {
    __block NSArray<NSData *> *result = nil;
    dispatch_sync(self.queue, ^{
        result = _events;
    });
    return result ?: @[];
}

+ (void)setEvents:(NSArray<NSData *> *)events {
    dispatch_sync(self.queue, ^{
        _events = events;
    });
}

+ (NSTimeInterval)interval {
    __block NSTimeInterval result = 0.2;
    dispatch_sync(self.queue, ^{
        result = _interval;
    });
    return result;
}

+ (void)setInterval:(NSTimeInterval)interval {
    dispatch_sync(self.queue, ^{
        _interval = interval;
    });
}

+ (nullable void(^)(void))completionHandler {
    __block void(^result)(void) = nil;
    dispatch_sync(self.queue, ^{
        result = _completionHandler;
    });
    return result;
}

+ (void)setCompletionHandler:(nullable void(^)(void))completionHandler {
    dispatch_sync(self.queue, ^{
        _completionHandler = completionHandler;
    });
}

+ (BOOL)echoMode {
    __block BOOL result = NO;
    dispatch_sync(self.queue, ^{
        result = _echoMode;
    });
    return result;
}

+ (void)setEchoMode:(BOOL)echoMode {
    dispatch_sync(self.queue, ^{
        _echoMode = echoMode;
    });
}

+ (void)configureWithEvents:(NSArray<NSData *> *)events interval:(NSTimeInterval)interval completion:(nullable void(^)(void))completion {
    dispatch_sync(self.queue, ^{
        _events = events;
        _interval = interval;
        _completionHandler = completion;
        _echoMode = NO;
    });
}

+ (void)enableEchoModeWithInterval:(NSTimeInterval)interval {
    dispatch_sync(self.queue, ^{
        _echoMode = YES;
        _interval = interval;
    });
}

+ (void)disableEchoMode {
    dispatch_sync(self.queue, ^{
        _echoMode = NO;
    });
}

+ (BOOL)canInitWithRequest:(NSURLRequest *)request {
    NSLog(@"🔍 [MockSSE] canInit called for URL: %@", request.URL.absoluteString ?: @"nil");
    NSLog(@"🔍 [MockSSE] HTTP Method: %@", request.HTTPMethod ?: @"nil");
    return YES;
}

+ (NSURLRequest *)canonicalRequestForRequest:(NSURLRequest *)request {
    return request;
}

- (void)startLoading {
    NSLog(@"🚀 [MockSSE] startLoading called for URL: %@", self.request.URL.absoluteString ?: @"nil");
    
    if (!self.client) {
        NSLog(@"❌ [MockSSE] No client available");
        return;
    }
    
    NSHTTPURLResponse *response = [[NSHTTPURLResponse alloc] initWithURL:self.request.URL ?: [NSURL URLWithString:@"https://mock.local/sse"]
                                                              statusCode:200
                                                             HTTPVersion:@"HTTP/1.1"
                                                            headerFields:@{@"Content-Type": @"text/event-stream"}];
    
    [self.client URLProtocol:self didReceiveResponse:response cacheStoragePolicy:NSURLCacheStorageNotAllowed];
    
    BOOL isEchoMode = self.class.echoMode;
    NSTimeInterval interval = self.class.interval;
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSArray<NSData *> *eventsToSend = nil;
        
        if (isEchoMode) {
            // Extract payload and generate echo events
            NSDictionary *payload = [self extractPayloadFromRequest:self.request];
            if (payload) {
                NSLog(@"🦜 [MockSSE] Echo mode: generating response for '%@' (threadId: %@, runId: %@)",
                      payload[@"message"] ?: @"", payload[@"threadId"] ?: @"", payload[@"runId"] ?: @"");
                
                NSArray<NSData *> *echoEvents = [self generateEchoEventsWithUserInput:payload[@"message"]
                                                                              threadId:payload[@"threadId"]
                                                                                 runId:payload[@"runId"]
                                                                          contextItems:payload[@"contextItems"] ?: @[]
                                                                          selectedTools:payload[@"selectedTools"] ?: @[]];
                eventsToSend = echoEvents;
            } else {
                NSLog(@"ℹ️  [MockSSE] No user payload found, skipping echo response");
                eventsToSend = @[];
            }
        } else {
            eventsToSend = self.class.events;
        }
        
        // Send events as SSE stream
        for (NSUInteger index = 0; index < eventsToSend.count; index++) {
            NSData *payload = eventsToSend[index];
            NSString *jsonString = [[NSString alloc] initWithData:payload encoding:NSUTF8StringEncoding];
            if (jsonString) {
                NSString *sseChunk = [NSString stringWithFormat:@"data: %@\n\n", jsonString];
                NSData *sseData = [sseChunk dataUsingEncoding:NSUTF8StringEncoding];
                if (sseData) {
                    [self.client URLProtocol:self didLoadData:sseData];
                }
            }
            [NSThread sleepForTimeInterval:interval];
            NSLog(@"🌐 [MockSSE] Emitted event #%lu", (unsigned long)(index + 1));
        }
        
        NSLog(@"✅ [MockSSE] Stream complete, finishing loading for URL: %@", self.request.URL.absoluteString ?: @"nil");
        [self.client URLProtocolDidFinishLoading:self];
        
        void(^completion)(void) = self.class.completionHandler;
        if (completion) {
            dispatch_sync(self.class.queue, ^{
                _completionHandler = nil;
            });
            completion();
        }
    });
}

- (void)stopLoading {
    // no-op: stream ends automatically
}

// MARK: - Payload Extraction

- (nullable NSDictionary *)extractPayloadFromRequest:(NSURLRequest *)request {
    NSData *bodyData = request.HTTPBody;
    if (!bodyData && request.HTTPBodyStream) {
        NSInputStream *stream = request.HTTPBodyStream;
        [stream open];
        NSMutableData *mutableData = [NSMutableData data];
        uint8_t buffer[1024];
        while ([stream hasBytesAvailable]) {
            NSInteger bytesRead = [stream read:buffer maxLength:1024];
            if (bytesRead > 0) {
                [mutableData appendBytes:buffer length:bytesRead];
            } else {
                break;
            }
        }
        [stream close];
        bodyData = mutableData;
    }
    
    if (!bodyData) {
        NSLog(@"⚠️ [MockSSE] Request body missing");
        return nil;
    }
    
    NSString *bodyString = [[NSString alloc] initWithData:bodyData encoding:NSUTF8StringEncoding];
    if (bodyString) {
        NSLog(@"📦 [MockSSE] Request body: %@", bodyString);
    }
    
    NSError *error = nil;
    id json = [NSJSONSerialization JSONObjectWithData:bodyData options:0 error:&error];
    if (error || ![json isKindOfClass:[NSDictionary class]]) {
        NSLog(@"⚠️ [MockSSE] Request body is not valid JSON: %@", error.localizedDescription);
        return nil;
    }
    
    NSDictionary *jsonDict = (NSDictionary *)json;
    NSString *threadId = jsonDict[@"threadId"];
    NSString *runId = jsonDict[@"runId"];
    
    if (!threadId || !runId) {
        NSLog(@"⚠️ [MockSSE] Missing threadId/runId in payload");
        return nil;
    }
    
    // Extract context items and tools
    NSMutableArray<NSDictionary *> *contextItems = [NSMutableArray array];
    NSMutableArray<NSDictionary *> *selectedTools = [NSMutableArray array];
    
    // Extract from AG-UI context array
    NSArray<NSDictionary *> *contextArray = jsonDict[@"context"];
    if ([contextArray isKindOfClass:[NSArray class]]) {
        for (NSDictionary *entry in contextArray) {
            NSString *key = entry[@"key"];
            NSDictionary *value = entry[@"value"];
            if ([key isEqualToString:@"convo_ui"] && [value isKindOfClass:[NSDictionary class]]) {
                NSArray<NSDictionary *> *items = value[@"contextItems"];
                if ([items isKindOfClass:[NSArray class]]) {
                    [contextItems addObjectsFromArray:items];
                }
            }
        }
    }
    
    // Extract tools
    NSArray<NSDictionary *> *toolsArray = jsonDict[@"tools"];
    if ([toolsArray isKindOfClass:[NSArray class]]) {
        for (NSDictionary *tool in toolsArray) {
            NSMutableDictionary *toolDict = [NSMutableDictionary dictionary];
            toolDict[@"itemId"] = tool[@"name"] ?: @"unknown";
            toolDict[@"displayName"] = tool[@"description"] ?: tool[@"name"] ?: @"unknown";
            if (tool[@"parameters"]) {
                toolDict[@"metadata"] = tool[@"parameters"];
            }
            [selectedTools addObject:toolDict];
        }
    }
    
    // Extract message
    NSString *message = jsonDict[@"message"];
    if (!message) {
        // Try messages array
        NSArray<NSDictionary *> *messages = jsonDict[@"messages"];
        if ([messages isKindOfClass:[NSArray class]]) {
            for (NSDictionary *entry in [messages reverseObjectEnumerator]) {
                NSString *role = entry[@"role"];
                if ([role isEqualToString:@"user"]) {
                    message = entry[@"content"];
                    break;
                }
            }
        }
    }
    
    if (!message) {
        NSLog(@"⚠️ [MockSSE] Could not locate user message in payload");
        return nil;
    }
    
    return @{
        @"message": message,
        @"threadId": threadId,
        @"runId": runId,
        @"contextItems": contextItems,
        @"selectedTools": selectedTools
    };
}

// MARK: - Echo Events Generation

- (NSArray<NSData *> *)generateEchoEventsWithUserInput:(NSString *)userInput
                                                threadId:(NSString *)threadId
                                                   runId:(NSString *)runId
                                            contextItems:(NSArray<NSDictionary *> *)contextItems
                                            selectedTools:(NSArray<NSDictionary *> *)selectedTools {
    NSString *messageId = [[NSUUID UUID] UUIDString];
    NSTimeInterval baseTimestamp = [[NSDate date] timeIntervalSince1970] * 1000;
    NSInteger baseTimestampInt = (NSInteger)baseTimestamp;
    
    NSArray<NSString *> *prefixDeltas = @[
        @"你好",
        @"！我是一只数字鹦鹉，",
        @"我只能模仿你说话。",
        @"这是你的原话：\n\n"
    ];
    
    NSMutableArray<NSDictionary *> *eventDicts = [NSMutableArray array];
    
    // RUN_STARTED
    [eventDicts addObject:@{
        @"type": @"RUN_STARTED",
        @"threadId": threadId,
        @"runId": runId,
        @"timestamp": @(baseTimestampInt)
    }];
    
    // TEXT_MESSAGE_START
    [eventDicts addObject:@{
        @"type": @"TEXT_MESSAGE_START",
        @"messageId": messageId,
        @"role": @"assistant",
        @"timestamp": @(baseTimestampInt + 100)
    }];
    
    // Prefix deltas
    for (NSUInteger index = 0; index < prefixDeltas.count; index++) {
        [eventDicts addObject:@{
            @"type": @"TEXT_MESSAGE_CONTENT",
            @"messageId": messageId,
            @"delta": prefixDeltas[index],
            @"timestamp": @(baseTimestampInt + 200 + (index * 150))
        }];
    }
    
    // Echo user input
    NSString *boldInput = [NSString stringWithFormat:@"**%@**", userInput];
    [eventDicts addObject:@{
        @"type": @"TEXT_MESSAGE_CONTENT",
        @"messageId": messageId,
        @"delta": boldInput,
        @"timestamp": @(baseTimestampInt + 200 + (prefixDeltas.count * 150))
    }];
    
    // Add context summary if any
    if (contextItems.count > 0) {
        NSMutableArray<NSString *> *contextLines = [NSMutableArray array];
        for (NSDictionary *item in contextItems) {
            NSString *summary = [self prettySummaryForContextItem:item];
            if (summary) {
                [contextLines addObject:summary];
            }
        }
        NSString *contextText = [NSString stringWithFormat:@"\n\n**Attached Context:**\n%@", [contextLines componentsJoinedByString:@"\n"]];
        [eventDicts addObject:@{
            @"type": @"TEXT_MESSAGE_CONTENT",
            @"messageId": messageId,
            @"delta": contextText,
            @"timestamp": @(baseTimestampInt + 200 + (prefixDeltas.count * 150) + 100)
        }];
    }
    
    // Add tool summary if any
    if (selectedTools.count > 0) {
        NSMutableArray<NSString *> *toolLines = [NSMutableArray array];
        for (NSDictionary *tool in selectedTools) {
            NSString *summary = [self prettyToolSummaryForTool:tool];
            if (summary) {
                [toolLines addObject:summary];
            }
        }
        NSString *toolText = [NSString stringWithFormat:@"\n\n🔧 **Using Tools:**\n%@", [toolLines componentsJoinedByString:@"\n"]];
        [eventDicts addObject:@{
            @"type": @"TEXT_MESSAGE_CONTENT",
            @"messageId": messageId,
            @"delta": toolText,
            @"timestamp": @(baseTimestampInt + 200 + (prefixDeltas.count * 150) + 200)
        }];
    }
    
    // TEXT_MESSAGE_END
    [eventDicts addObject:@{
        @"type": @"TEXT_MESSAGE_END",
        @"messageId": messageId,
        @"timestamp": @(baseTimestampInt + 1000)
    }];
    
    // RUN_FINISHED
    [eventDicts addObject:@{
        @"type": @"RUN_FINISHED",
        @"threadId": threadId,
        @"runId": runId,
        @"timestamp": @(baseTimestampInt + 1000)
    }];
    
    // Convert to NSData array
    NSMutableArray<NSData *> *events = [NSMutableArray array];
    for (NSDictionary *dict in eventDicts) {
        NSError *error = nil;
        NSData *data = [NSJSONSerialization dataWithJSONObject:dict options:0 error:&error];
        if (data && !error) {
            [events addObject:data];
        }
    }
    
    return [events copy];
}

- (nullable NSString *)prettySummaryForContextItem:(NSDictionary *)item {
    NSString *displayName = item[@"displayName"] ?: @"Unknown";
    NSString *itemId = item[@"displayName"] ?: @"";
    
    NSDictionary *metadata = item[@"metadata"];
    if ([metadata isKindOfClass:[NSDictionary class]]) {
        NSString *service = metadata[@"service"];
        NSString *description = metadata[@"description"];
        
        NSMutableString *info = [NSMutableString stringWithFormat:@"**%@**", displayName];
        if (description) {
            [info appendFormat:@": %@", description];
        }
        if (service) {
            [info appendFormat:@" (via %@)", service];
        }
        return [info copy];
    } else {
        return [NSString stringWithFormat:@"**%@** (ID: %@)", displayName, itemId];
    }
}

- (nullable NSString *)prettyToolSummaryForTool:(NSDictionary *)tool {
    NSString *displayName = tool[@"displayName"] ?: @"Unknown Tool";
    NSString *itemId = tool[@"itemId"] ?: @"";
    
    NSDictionary *metadata = tool[@"metadata"];
    if ([metadata isKindOfClass:[NSDictionary class]]) {
        NSString *service = metadata[@"service"];
        NSString *description = metadata[@"description"];
        
        NSMutableString *info = [NSMutableString stringWithFormat:@"**%@**", displayName];
        if (description) {
            [info appendFormat:@": %@", description];
        }
        if (service) {
            [info appendFormat:@" (via %@)", service];
        }
        return [info copy];
    } else {
        return [NSString stringWithFormat:@"**%@** (ID: %@)", displayName, itemId];
    }
}

@end


