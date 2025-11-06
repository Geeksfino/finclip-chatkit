//
//  MainChatViewController.m
//  AI-Bank-OC
//
//  Main chat interface demonstrating ChatKit integration in Objective-C
//

#import "MainChatViewController.h"
#import "ChatViewController.h"
#import "DrawerContainerViewController.h"
#import "RuntimeCoordinator.h"
#import "ConversationManager.h"
#import "AgentCatalog.h"

@interface MainChatViewController ()

@property (nonatomic, strong) RuntimeCoordinator *runtimeCoordinator;
@property (nonatomic, strong) ConversationManager *conversationManager;
@property (nonatomic, strong) ChatViewController *chatViewController;
@property (nonatomic, strong) DrawerContainerViewController *drawerContainer;
@property (nonatomic, strong) UIButton *menuButton;

@end

@implementation MainChatViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.title = @"AI-Bank";
    self.view.backgroundColor = [UIColor systemBackgroundColor];
    
    // Initialize coordinators
    [self setupCoordinators];
    
    // Setup UI
    [self setupUI];
    
    // Load default agent
    [self loadDefaultAgent];
}

- (void)setupCoordinators {
    self.conversationManager = [[ConversationManager alloc] init];
    self.runtimeCoordinator = [[RuntimeCoordinator alloc] initWithConversationManager:self.conversationManager];
}

- (void)setupUI {
    // Setup drawer container with chat view
    self.chatViewController = [[ChatViewController alloc] initWithRuntimeCoordinator:self.runtimeCoordinator];
    self.drawerContainer = [[DrawerContainerViewController alloc] initWithContentViewController:self.chatViewController];
    
    // Add drawer container as child
    [self addChildViewController:self.drawerContainer];
    self.drawerContainer.view.frame = self.view.bounds;
    self.drawerContainer.view.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    [self.view addSubview:self.drawerContainer.view];
    [self.drawerContainer didMoveToParentViewController:self];
    
    // Setup navigation bar button
    self.menuButton = [UIButton buttonWithType:UIButtonTypeSystem];
    [self.menuButton setImage:[UIImage systemImageNamed:@"line.3.horizontal"] forState:UIControlStateNormal];
    [self.menuButton addTarget:self action:@selector(toggleDrawer) forControlEvents:UIControlEventTouchUpInside];
    UIBarButtonItem *menuBarButton = [[UIBarButtonItem alloc] initWithCustomView:self.menuButton];
    self.navigationItem.leftBarButtonItem = menuBarButton;
}

- (void)loadDefaultAgent {
    AgentCatalog *catalog = [[AgentCatalog alloc] init];
    AgentInfo *defaultAgent = [catalog.agents firstObject];
    
    if (defaultAgent) {
        [self.runtimeCoordinator loadAgentWithInfo:defaultAgent];
    }
}

- (void)toggleDrawer {
    [self.drawerContainer toggleDrawer];
}

@end


