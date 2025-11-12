//
//  ConnectionMode.m
//  SimpleChatObjC
//
//  Objective-C wrapper for ConnectionMode enum
//

#import "ConnectionMode.h"

@implementation ConnectionMode

+ (instancetype)fixtureMode {
    return [[self alloc] initWithFixture:YES serverURL:nil];
}

+ (instancetype)remoteModeWithURL:(NSURL *)url {
    return [[self alloc] initWithFixture:NO serverURL:url];
}

- (instancetype)initWithFixture:(BOOL)isFixture serverURL:(nullable NSURL *)serverURL {
    self = [super init];
    if (self) {
        _isFixture = isFixture;
        _serverURL = serverURL;
    }
    return self;
}

- (NSURL *)serverURLForConnection {
    if (self.isFixture) {
        return [NSURL URLWithString:@"https://mock-fixture.local"];
    }
    return self.serverURL ?: [NSURL URLWithString:@"https://mock-fixture.local"];
}

- (id)copyWithZone:(nullable NSZone *)zone {
    return [[ConnectionMode alloc] initWithFixture:self.isFixture serverURL:self.serverURL];
}

- (BOOL)isEqual:(id)object {
    if (self == object) return YES;
    if (![object isKindOfClass:[ConnectionMode class]]) return NO;
    
    ConnectionMode *other = (ConnectionMode *)object;
    if (self.isFixture != other.isFixture) return NO;
    if (self.isFixture) return YES; // Both fixture, equal
    
    return [self.serverURL isEqual:other.serverURL];
}

- (NSUInteger)hash {
    if (self.isFixture) {
        return 1;
    }
    return [self.serverURL hash];
}

- (NSString *)description {
    if (self.isFixture) {
        return @"ConnectionMode(fixture)";
    }
    return [NSString stringWithFormat:@"ConnectionMode(remote: %@)", self.serverURL];
}

@end


