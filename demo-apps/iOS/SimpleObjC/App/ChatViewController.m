//
//  ChatViewController.m
//  SimpleChatObjC
//
//  Chat view controller - Refactored to use ChatKitConversationViewController
//  This file is kept for backwards compatibility but is no longer used
//  The new implementation uses ChatKitConversationViewController directly
//

#import "ChatViewController.h"
@import FinClipChatKit;
@import ConvoUI;
#import <FinClipChatKit/ChatKit-ObjC.h>
#import <FinClipChatKit/ChatKitConvoUIShims.h>

// NOTE: This implementation is deprecated.
// New code should use ChatKitConversationViewController directly.
// This file is kept for backwards compatibility only.

@implementation ChatViewController

- (instancetype)initWithRecord:(ConversationRecord *)record
                       adapter:(id)adapter
                    coordinator:(id)coordinator {
    // Deprecated - use ChatKitConversationViewController instead
    self = [super initWithNibName:nil bundle:nil];
    if (self) {
        // Minimal implementation for backwards compatibility
    }
    return self;
}

- (NSUUID *)sessionIdentifier {
    return nil;
}

@end
