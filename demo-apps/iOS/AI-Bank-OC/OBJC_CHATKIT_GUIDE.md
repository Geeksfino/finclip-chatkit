# Using ChatKit with Objective-C

This guide provides specific guidance for using the Finclip ChatKit framework in Objective-C projects. ChatKit is written in Swift, but exposes a full Objective-C compatible API.

## Table of Contents

- [Importing ChatKit](#importing-chatkit)
- [Key Differences from Swift](#key-differences-from-swift)
- [Common Patterns](#common-patterns)
- [Type Conversions](#type-conversions)
- [Memory Management](#memory-management)
- [Error Handling](#error-handling)
- [Best Practices](#best-practices)

## Importing ChatKit

### Module Import (Recommended)

```objective-c
@import ChatKit;
```

This is the preferred method as it imports the framework as a module with full API availability.

### Framework Import (Alternative)

```objective-c
#import <ChatKit/ChatKit.h>
```

## Key Differences from Swift

### Property Declarations

**Swift:**
```swift
var agentId: String
let name: String
var description: String?
```

**Objective-C:**
```objective-c
@property (nonatomic, strong) NSString *agentId;
@property (nonatomic, strong, readonly) NSString *name;
@property (nonatomic, strong, nullable) NSString *agentDescription;
```

### Initialization

**Swift:**
```swift
init(coordinator: RuntimeCoordinator) {
    self.coordinator = coordinator
    super.init()
}
```

**Objective-C:**
```objective-c
- (instancetype)initWithCoordinator:(RuntimeCoordinator *)coordinator {
    self = [super init];
    if (self) {
        _coordinator = coordinator;
    }
    return self;
}
```

### Closures/Blocks

**Swift:**
```swift
func sendMessage(_ text: String, completion: @escaping (String?, Error?) -> Void) {
    // implementation
}

// Usage
sendMessage("Hello") { response, error in
    guard let response = response else { return }
    print(response)
}
```

**Objective-C:**
```objective-c
- (void)sendMessage:(NSString *)text 
         completion:(void (^)(NSString *_Nullable response, NSError *_Nullable error))completion {
    // implementation
}

// Usage
[self sendMessage:@"Hello" completion:^(NSString *response, NSError *error) {
    if (response) {
        NSLog(@"%@", response);
    }
}];
```

### Optionals

**Swift:**
```swift
var agent: AgentInfo?

if let agent = agent {
    print(agent.name)
}
```

**Objective-C:**
```objective-c
@property (nonatomic, strong, nullable) AgentInfo *agent;

if (self.agent) {
    NSLog(@"%@", self.agent.name);
}
```

### String Interpolation

**Swift:**
```swift
let message = "Hello, \(name)! Balance: \(balance)"
```

**Objective-C:**
```objective-c
NSString *message = [NSString stringWithFormat:@"Hello, %@! Balance: %.2f", name, balance];
```

## Common Patterns

### Delegate Pattern

**Swift:**
```swift
protocol ChatViewDelegate: AnyObject {
    func chatView(_ view: ChatView, didReceiveMessage message: String)
}

class ChatViewController: UIViewController, ChatViewDelegate {
    func chatView(_ view: ChatView, didReceiveMessage message: String) {
        // handle message
    }
}
```

**Objective-C:**
```objective-c
@protocol ChatViewDelegate <NSObject>
- (void)chatView:(ChatView *)view didReceiveMessage:(NSString *)message;
@end

@interface ChatViewController : UIViewController <ChatViewDelegate>
@end

@implementation ChatViewController

- (void)chatView:(ChatView *)view didReceiveMessage:(NSString *)message {
    // handle message
}

@end
```

### Enumerations

**Swift:**
```swift
enum AgentState {
    case idle
    case loading
    case ready
    case error(String)
}
```

**Objective-C:**
```objective-c
typedef NS_ENUM(NSInteger, AgentState) {
    AgentStateIdle,
    AgentStateLoading,
    AgentStateReady,
    AgentStateError
};
```

Note: Swift enums with associated values don't translate directly to Objective-C. Use separate properties or classes instead.

### Collections

**Swift:**
```swift
var agents: [AgentInfo] = []
var metadata: [String: Any] = [:]
```

**Objective-C:**
```objective-c
@property (nonatomic, strong) NSMutableArray<AgentInfo *> *agents;
@property (nonatomic, strong) NSMutableDictionary<NSString *, id> *metadata;
```

## Type Conversions

### Common Type Mappings

| Swift | Objective-C |
|-------|-------------|
| `String` | `NSString *` |
| `Int` | `NSInteger` |
| `Double` | `CGFloat` / `double` |
| `Bool` | `BOOL` |
| `Array<T>` | `NSArray<T> *` |
| `Dictionary<K, V>` | `NSDictionary<K, V> *` |
| `Data` | `NSData *` |
| `URL` | `NSURL *` |
| `Date` | `NSDate *` |
| `UUID` | `NSUUID *` |

### Converting Between Types

```objective-c
// String to URL
NSString *urlString = @"https://api.example.com";
NSURL *url = [NSURL URLWithString:urlString];

// Number conversions
NSInteger count = 42;
NSNumber *numberCount = @(count);

// Array operations
NSArray<NSString *> *items = @[@"one", @"two", @"three"];
NSString *first = items.firstObject;
NSString *last = items.lastObject;
NSInteger count = items.count;

// Dictionary operations
NSDictionary *dict = @{
    @"key1": @"value1",
    @"key2": @42
};
NSString *value = dict[@"key1"];
```

## Memory Management

### Retain Cycles

**Problem:**
```objective-c
// This creates a retain cycle!
[self.chatRuntime sendMessage:text completion:^(NSString *response, NSError *error) {
    [self updateUI:response];  // self is retained by the block
}];
```

**Solution:**
```objective-c
// Use weak-strong dance
__weak typeof(self) weakSelf = self;
[self.chatRuntime sendMessage:text completion:^(NSString *response, NSError *error) {
    __strong typeof(weakSelf) strongSelf = weakSelf;
    if (!strongSelf) return;
    [strongSelf updateUI:response];
}];
```

### Property Attributes

```objective-c
// Strong reference (default for objects)
@property (nonatomic, strong) AgentManager *manager;

// Weak reference (for delegates, to avoid retain cycles)
@property (nonatomic, weak) id<ChatViewDelegate> delegate;

// Copy (for blocks and immutable objects)
@property (nonatomic, copy) void (^completionHandler)(NSString *, NSError *);

// Assign (for primitives)
@property (nonatomic, assign) NSInteger count;
```

## Error Handling

### Swift Error Handling

**Swift:**
```swift
do {
    try chatRuntime.configure(with: config)
} catch {
    print("Error: \(error)")
}
```

**Objective-C:**
```objective-c
NSError *error = nil;
BOOL success = [self.chatRuntime configureWithConfig:config error:&error];
if (!success) {
    NSLog(@"Error: %@", error.localizedDescription);
}
```

### Completion Handlers with Errors

```objective-c
- (void)fetchData:(void (^)(NSData *_Nullable data, NSError *_Nullable error))completion {
    // On success
    completion(data, nil);
    
    // On error
    NSError *error = [NSError errorWithDomain:@"com.example.app"
                                         code:1001
                                     userInfo:@{NSLocalizedDescriptionKey: @"Failed to fetch data"}];
    completion(nil, error);
}
```

## Best Practices

### 1. Use Nullability Annotations

```objective-c
// Good: Clear nullability
- (void)loadAgent:(AgentInfo * _Nonnull)agent 
       completion:(void (^ _Nullable)(BOOL success))completion;

// Better: Use regions for multiple declarations
NS_ASSUME_NONNULL_BEGIN

@interface AgentManager : NSObject

@property (nonatomic, strong) AgentInfo *currentAgent;
@property (nonatomic, strong, nullable) NSError *lastError;

- (void)loadAgent:(AgentInfo *)agent 
       completion:(nullable void (^)(BOOL success))completion;

@end

NS_ASSUME_NONNULL_END
```

### 2. Use Generics for Type Safety

```objective-c
// Good: Generic collections
@property (nonatomic, strong) NSArray<AgentInfo *> *agents;
@property (nonatomic, strong) NSDictionary<NSString *, AgentInfo *> *agentMap;

// Usage
AgentInfo *agent = self.agents.firstObject;  // Type is known
```

### 3. Prefer Blocks Over Delegates for Simple Callbacks

```objective-c
// For simple callbacks, use blocks
- (void)fetchAgents:(void (^)(NSArray<AgentInfo *> *agents, NSError *error))completion;

// For ongoing communication, use delegates
@protocol AgentManagerDelegate <NSObject>
- (void)agentManager:(AgentManager *)manager didUpdateAgent:(AgentInfo *)agent;
- (void)agentManager:(AgentManager *)manager didEncounterError:(NSError *)error;
@end
```

### 4. Main Thread for UI Updates

```objective-c
- (void)updateWithResponse:(NSString *)response {
    // Ensure UI updates on main thread
    dispatch_async(dispatch_get_main_queue(), ^{
        self.messageLabel.text = response;
        [self.tableView reloadData];
    });
}
```

### 5. Use Modern Objective-C Syntax

```objective-c
// Literal syntax
NSArray *array = @[@"one", @"two", @"three"];
NSDictionary *dict = @{@"key": @"value"};
NSNumber *num = @42;

// Subscripting
NSString *item = array[0];
NSString *value = dict[@"key"];

// Property dot notation
self.agent.name = @"Banking Assistant";
NSInteger count = self.conversations.count;
```

## Working with ChatKit API

### Initializing ChatKit Runtime

```objective-c
#import "RuntimeCoordinator.h"
@import ChatKit;

@interface RuntimeCoordinator ()
@property (nonatomic, strong) ChatKitRuntime *runtime;
@end

@implementation RuntimeCoordinator

- (instancetype)init {
    self = [super init];
    if (self) {
        [self setupRuntime];
    }
    return self;
}

- (void)setupRuntime {
    ChatKitConfiguration *config = [[ChatKitConfiguration alloc] init];
    config.apiKey = @"your-api-key";
    config.serverURL = [NSURL URLWithString:@"https://api.example.com"];
    
    self.runtime = [[ChatKitRuntime alloc] initWithConfiguration:config];
}

@end
```

### Sending Messages

```objective-c
- (void)sendMessage:(NSString *)message 
         completion:(void (^)(NSString *response, NSError *error))completion {
    __weak typeof(self) weakSelf = self;
    
    [self.runtime sendMessage:message completion:^(ChatKitResponse *response, NSError *error) {
        __strong typeof(weakSelf) strongSelf = weakSelf;
        if (!strongSelf) return;
        
        if (error) {
            completion(nil, error);
            return;
        }
        
        completion(response.text, nil);
    }];
}
```

### Implementing Delegates

```objective-c
@interface ChatViewController () <ChatViewDelegate>
@end

@implementation ChatViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.chatView.delegate = self;
}

#pragma mark - ChatViewDelegate

- (void)chatView:(ChatView *)view didReceiveMessage:(NSString *)message {
    NSLog(@"Received: %@", message);
}

- (void)chatView:(ChatView *)view didEncounterError:(NSError *)error {
    NSLog(@"Error: %@", error.localizedDescription);
}

@end
```

## Debugging Tips

### 1. Enable Logging

```objective-c
#ifdef DEBUG
    #define DLog(fmt, ...) NSLog((@"%s [Line %d] " fmt), __PRETTY_FUNCTION__, __LINE__, ##__VA_ARGS__)
#else
    #define DLog(...)
#endif

// Usage
DLog(@"Agent loaded: %@", agent.name);
```

### 2. Check for Nil Values

```objective-c
- (void)processAgent:(AgentInfo *)agent {
    NSParameterAssert(agent != nil);
    NSAssert(agent.agentId.length > 0, @"Agent ID must not be empty");
    
    // Process agent
}
```

### 3. Use Instruments for Memory Issues

- Product → Profile (⌘I)
- Choose "Leaks" or "Allocations"
- Look for retain cycles and memory leaks

## Migration from Swift

If you have existing Swift ChatKit code and need to migrate to Objective-C:

1. **Start with interfaces** - Convert Swift protocols and classes to Objective-C headers
2. **Convert properties** - Map Swift properties to Objective-C `@property` declarations
3. **Update method signatures** - Follow Objective-C naming conventions
4. **Replace closures** - Convert Swift closures to Objective-C blocks
5. **Handle optionals** - Use nullable/nonnull annotations
6. **Update error handling** - Convert `try/catch` to `NSError **` pattern
7. **Test thoroughly** - Verify all ChatKit integration points

## Further Resources

- [ChatKit API Documentation](../docs/)
- [Objective-C Programming Guide](https://developer.apple.com/library/archive/documentation/Cocoa/Conceptual/ProgrammingWithObjectiveC/Introduction/Introduction.html)
- [Working with Swift from Objective-C](https://developer.apple.com/documentation/swift/importing-swift-into-objective-c)
- [AI-Bank Swift Example](../AI-Bank/) - Compare implementations

## Common Issues and Solutions

### Issue: "Module 'ChatKit' not found"

**Solution:**
1. Ensure ChatKit is added as a dependency in Package.swift
2. Clean build folder (⌘⇧K)
3. Resolve packages in Xcode

### Issue: "Use of undeclared identifier"

**Solution:**
1. Import ChatKit: `@import ChatKit;`
2. Check header imports
3. Verify target membership of files

### Issue: Retain cycles causing memory leaks

**Solution:**
```objective-c
__weak typeof(self) weakSelf = self;
[object doSomethingWithCompletion:^{
    __strong typeof(weakSelf) strongSelf = weakSelf;
    if (!strongSelf) return;
    // Use strongSelf
}];
```

---

For questions or issues, refer to the main ChatKit documentation or open an issue in the repository.


