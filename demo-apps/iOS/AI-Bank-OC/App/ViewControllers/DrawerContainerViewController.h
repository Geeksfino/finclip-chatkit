//
//  DrawerContainerViewController.h
//  AI-Bank-OC
//
//  Container view controller managing drawer/side menu functionality
//

#import <UIKit/UIKit.h>

@interface DrawerContainerViewController : UIViewController

- (instancetype)initWithContentViewController:(UIViewController *)contentViewController;
- (void)toggleDrawer;

@end


