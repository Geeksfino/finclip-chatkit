//
//  DrawerContainerViewController.m
//  AI-Bank-OC
//
//  Container view controller managing drawer/side menu functionality
//

#import "DrawerContainerViewController.h"
#import "DrawerViewController.h"

@interface DrawerContainerViewController ()

@property (nonatomic, strong) UIViewController *contentViewController;
@property (nonatomic, strong) DrawerViewController *drawerViewController;
@property (nonatomic, assign) BOOL isDrawerOpen;
@property (nonatomic, strong) UIView *overlayView;

@end

@implementation DrawerContainerViewController

- (instancetype)initWithContentViewController:(UIViewController *)contentViewController {
    self = [super init];
    if (self) {
        _contentViewController = contentViewController;
        _isDrawerOpen = NO;
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.view.backgroundColor = [UIColor systemBackgroundColor];
    
    // Setup drawer
    self.drawerViewController = [[DrawerViewController alloc] init];
    
    // Add content view controller
    [self addChildViewController:self.contentViewController];
    self.contentViewController.view.frame = self.view.bounds;
    self.contentViewController.view.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    [self.view addSubview:self.contentViewController.view];
    [self.contentViewController didMoveToParentViewController:self];
    
    // Add drawer view controller
    [self addChildViewController:self.drawerViewController];
    CGFloat drawerWidth = 280;
    self.drawerViewController.view.frame = CGRectMake(-drawerWidth, 0, drawerWidth, self.view.bounds.size.height);
    self.drawerViewController.view.autoresizingMask = UIViewAutoresizingFlexibleHeight;
    [self.view insertSubview:self.drawerViewController.view atIndex:0];
    [self.drawerViewController didMoveToParentViewController:self];
    
    // Setup overlay
    self.overlayView = [[UIView alloc] initWithFrame:self.view.bounds];
    self.overlayView.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.5];
    self.overlayView.alpha = 0;
    self.overlayView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    [self.view insertSubview:self.overlayView belowSubview:self.contentViewController.view];
    
    UITapGestureRecognizer *tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(overlayTapped)];
    [self.overlayView addGestureRecognizer:tapGesture];
}

- (void)toggleDrawer {
    if (self.isDrawerOpen) {
        [self closeDrawer];
    } else {
        [self openDrawer];
    }
}

- (void)openDrawer {
    self.isDrawerOpen = YES;
    
    [UIView animateWithDuration:0.3 animations:^{
        CGRect drawerFrame = self.drawerViewController.view.frame;
        drawerFrame.origin.x = 0;
        self.drawerViewController.view.frame = drawerFrame;
        
        CGRect contentFrame = self.contentViewController.view.frame;
        contentFrame.origin.x = drawerFrame.size.width;
        self.contentViewController.view.frame = contentFrame;
        
        self.overlayView.alpha = 1;
    }];
}

- (void)closeDrawer {
    self.isDrawerOpen = NO;
    
    [UIView animateWithDuration:0.3 animations:^{
        CGRect drawerFrame = self.drawerViewController.view.frame;
        drawerFrame.origin.x = -drawerFrame.size.width;
        self.drawerViewController.view.frame = drawerFrame;
        
        CGRect contentFrame = self.contentViewController.view.frame;
        contentFrame.origin.x = 0;
        self.contentViewController.view.frame = contentFrame;
        
        self.overlayView.alpha = 0;
    }];
}

- (void)overlayTapped {
    [self closeDrawer];
}

@end


