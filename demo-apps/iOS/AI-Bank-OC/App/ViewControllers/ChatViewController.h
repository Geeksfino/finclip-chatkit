//
//  ChatViewController.h
//  AI-Bank-OC
//
//  Chat view controller demonstrating ChatKit usage in Objective-C
//

#import <UIKit/UIKit.h>

@class RuntimeCoordinator;

@interface ChatViewController : UIViewController

- (instancetype)initWithRuntimeCoordinator:(RuntimeCoordinator *)coordinator;

@end


