//
//  ConversationListViewController.m
//  SimpleChatObjC
//
//  Conversation list screen for SimpleChatObjC - Refactored to use ChatKitConversationListViewController
//

#import "ConversationListViewController.h"
#import <FinClipChatKit/FinClipChatKit-Swift.h>

@interface ConversationListViewController () <CKTConversationListViewControllerDelegate>

@property (nonatomic, strong) CKTChatKitCoordinator *coordinator;
@property (nonatomic, strong) ChatKitConversationListViewController *listViewController;

@end

@implementation ConversationListViewController

- (instancetype)initWithCoordinator:(ChatCoordinator *)coordinator {
    // For backwards compatibility - not recommended
    return [self initWithSDKCoordinator:nil];
}

- (instancetype)initWithSDKCoordinator:(CKTChatKitCoordinator *)coordinator {
    if (!coordinator) {
        return nil;
    }
    
    self = [super initWithNibName:nil bundle:nil];
    if (self) {
        _coordinator = coordinator;
        _autoCreateConversation = NO;
        
        // Configure the conversation list component
        CKTConversationListConfiguration *config = [CKTConversationListConfiguration defaultConfiguration];
        config.searchPlaceholder = @"Search conversations...";
        config.showHeader = NO; // We'll use navigation bar instead
        config.showSearchBar = YES;
        config.showNewButton = YES;
        config.enableSwipeToDelete = YES;
        config.enableLongPress = NO; // Can enable later if needed
        config.rowHeight = 72.0;
        
        // Create the list view controller using the ObjC-friendly initializer
        _listViewController = [[ChatKitConversationListViewController alloc] initWithObjCCoordinator:coordinator
                                                                                      objcConfiguration:config];
        _listViewController.objcDelegate = self;
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // Configure navigation bar
    self.title = @"Conversations";
    
    UIBarButtonItem *disconnectButton = [[UIBarButtonItem alloc] initWithTitle:@"Disconnect"
                                                                         style:UIBarButtonItemStylePlain
                                                                        target:self
                                                                        action:@selector(disconnectTapped)];
    self.navigationItem.leftBarButtonItem = disconnectButton;
    
    // Embed the list view controller
    [self addChildViewController:self.listViewController];
    [self.view addSubview:self.listViewController.view];
    self.listViewController.view.translatesAutoresizingMaskIntoConstraints = NO;
    [self.listViewController didMoveToParentViewController:self];
    
    [NSLayoutConstraint activateConstraints:@[
        [self.listViewController.view.topAnchor constraintEqualToAnchor:self.view.topAnchor],
        [self.listViewController.view.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor],
        [self.listViewController.view.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor],
        [self.listViewController.view.bottomAnchor constraintEqualToAnchor:self.view.bottomAnchor]
    ]];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    if (self.autoCreateConversation) {
        self.autoCreateConversation = NO;
        // Check if we have any conversations by checking the coordinator's records
        // The component already subscribes to records, so we can check after a brief delay
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            CKTConversationManager *manager = [[CKTConversationManager alloc] init];
            [manager attachToCoordinator:self.coordinator];
            if (manager.records.count == 0) {
                [self createNewConversation];
            }
        });
    }
}

- (void)disconnectTapped {
    [self.navigationController popViewControllerAnimated:YES];
}

- (void)createNewConversation {
    // Use coordinator's high-level API for creating conversations
    NSUUID *agentId = [[NSUUID alloc] initWithUUIDString:@"E1E72B3D-845D-4F5D-B6CA-5550F2643E6B"];
    
    [self.coordinator startConversationWithAgentId:agentId
                                               title:nil
                                           agentName:@"My Agent"
                                          completion:^(CKTConversationRecord *record, id conversation, NSError *error) {
        if (error) {
            [self showAlertWithTitle:@"Error" message:error.localizedDescription];
            return;
        }
        
        if (record && conversation) {
            // Create ChatKitConversationViewController directly with the new conversation
            CKTConversationConfiguration *chatConfig = [CKTConversationConfiguration defaultConfiguration];
            chatConfig.showStatusBanner = YES;
            chatConfig.showWelcomeMessage = YES;
            chatConfig.welcomeMessage = @"Hello! How can I help you today?";
            chatConfig.statusBannerAutoHide = YES;
            chatConfig.statusBannerAutoHideDelay = 2.0;
            
            ChatKitConversationViewController *chatVC = [[ChatKitConversationViewController alloc] initWithObjCRecord:record
                                                                                                       conversation:conversation
                                                                                                    objcCoordinator:self.coordinator
                                                                                                  objcConfiguration:chatConfig];
            chatVC.title = record.title.length > 0 ? record.title : @"Untitled";
            
            dispatch_async(dispatch_get_main_queue(), ^{
                [self.navigationController pushViewController:chatVC animated:YES];
            });
        }
    }];
}

- (void)openChatWithRecord:(CKTConversationRecord *)record {
    // Use coordinator's high-level API to get conversation and record
    [self.coordinator conversationWithSessionId:record.sessionId
                                    completion:^(CKTConversationRecord *loadedRecord, id conversation, NSError *error) {
        if (error) {
            [self showAlertWithTitle:@"Error" message:error.localizedDescription];
            return;
        }
        
        if (!loadedRecord || !conversation) {
            [self showAlertWithTitle:@"Error" message:@"Failed to load conversation"];
            return;
        }
        
        // Create ChatKitConversationViewController using ObjC initializer
        CKTConversationConfiguration *chatConfig = [CKTConversationConfiguration defaultConfiguration];
        chatConfig.showStatusBanner = YES;
        chatConfig.showWelcomeMessage = YES;
        chatConfig.welcomeMessage = @"Hello! How can I help you today?";
        chatConfig.statusBannerAutoHide = YES;
        chatConfig.statusBannerAutoHideDelay = 2.0;
        
        ChatKitConversationViewController *chatVC = [[ChatKitConversationViewController alloc] initWithObjCRecord:loadedRecord
                                                                                                       conversation:conversation
                                                                                                    objcCoordinator:self.coordinator
                                                                                                  objcConfiguration:chatConfig];
        chatVC.title = loadedRecord.title.length > 0 ? loadedRecord.title : @"Untitled";
        
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.navigationController pushViewController:chatVC animated:YES];
        });
    }];
}

- (void)showAlertWithTitle:(NSString *)title message:(NSString *)message {
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:title
                                                                   message:message
                                                            preferredStyle:UIAlertControllerStyleAlert];
    [alert addAction:[UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:nil]];
    [self presentViewController:alert animated:YES completion:nil];
}

#pragma mark - CKTConversationListViewControllerDelegate

- (void)conversationListViewController:(ChatKitConversationListViewController *)controller
                  didSelectConversation:(CKTConversationRecord *)record {
    [self openChatWithRecord:record];
}

- (void)conversationListViewControllerDidRequestNewConversation:(ChatKitConversationListViewController *)controller {
    [self createNewConversation];
}

@end
