//
//  ConversationRecord.h
//  AI-Bank-OC
//
//  Model representing a conversation record
//

#import <Foundation/Foundation.h>

@interface ConversationRecord : NSObject

@property (nonatomic, strong) NSString *conversationId;
@property (nonatomic, strong) NSString *title;
@property (nonatomic, strong) NSDate *createdAt;
@property (nonatomic, strong) NSDate *updatedAt;
@property (nonatomic, strong) NSString *agentId;

@end


