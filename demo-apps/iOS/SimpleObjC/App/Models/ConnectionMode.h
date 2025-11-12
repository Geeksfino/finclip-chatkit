//
//  ConnectionMode.h
//  SimpleChatObjC
//
//  Objective-C wrapper for ConnectionMode enum
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/// Represents connection mode for ChatKit
@interface ConnectionMode : NSObject <NSCopying>

/// Whether this is fixture mode
@property (nonatomic, readonly) BOOL isFixture;

/// Server URL (nil for fixture mode)
@property (nonatomic, readonly, nullable) NSURL *serverURL;

/// Initialize with fixture mode
+ (instancetype)fixtureMode;

/// Initialize with remote mode
+ (instancetype)remoteModeWithURL:(NSURL *)url;

/// Get server URL (returns mock URL for fixture mode)
- (NSURL *)serverURLForConnection;

@end

NS_ASSUME_NONNULL_END


