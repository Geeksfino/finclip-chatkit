//
//  MockSSEURLProtocol.h
//  SimpleChatObjC
//
//  URLProtocol that replays AG-UI events as a Server-Sent Events (SSE) stream
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/// URLProtocol that replays AG-UI events as a Server-Sent Events (SSE) stream
@interface MockSSEURLProtocol : NSURLProtocol

/// Configure with specific events
+ (void)configureWithEvents:(NSArray<NSData *> *)events interval:(NSTimeInterval)interval completion:(nullable void(^)(void))completion;

/// Enable echo mode (responds with user input)
+ (void)enableEchoModeWithInterval:(NSTimeInterval)interval;

/// Disable echo mode
+ (void)disableEchoMode;

@end

NS_ASSUME_NONNULL_END


