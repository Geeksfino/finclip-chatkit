//
//  ConversationListViewController.m
//  SimpleObjC
//
//  Thin wrapper that embeds ChatKitConversationListViewController
//

#import "ConversationListViewController.h"
#import "NoteContextProvider.h"
#import <FinClipChatKit/FinClipChatKit-Swift.h>
#import <ConvoUI/FinConvoMessageInputView.h>

@interface ConversationListViewController () <CKTConversationListViewControllerDelegate>
@property (nonatomic, strong) CKTChatKitCoordinator *coordinator;
@property (nonatomic, strong) ChatKitConversationListViewController *listViewController;
@end

@implementation ConversationListViewController

- (instancetype)initWithCoordinator:(CKTChatKitCoordinator *)coordinator {
    self = [super initWithNibName:nil bundle:nil];
    if (self) {
        _coordinator = coordinator;
        
        // Configure ChatKit list view
        CKTConversationListConfiguration *config = [CKTConversationListConfiguration defaultConfiguration];
        config.headerTitle = @"SimpleObjC";
        config.headerIcon = [UIImage systemImageNamed:@"bubble.left.and.bubble.right.fill"];
        config.searchPlaceholder = @"Search conversations...";
        config.showHeader = YES;
        config.showSearchBar = YES;
        config.showNewButton = YES;
        config.enableSwipeToDelete = YES;
        config.searchEnabled = YES;
        config.rowHeight = 72.0;
        
        // Create and embed ChatKit list view controller
        _listViewController = [[ChatKitConversationListViewController alloc] initWithObjCCoordinator:coordinator
                                                                                    objcConfiguration:config];
        _listViewController.objcDelegate = self;
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // Add ChatKit list view controller as child
    [self addChildViewController:self.listViewController];
    self.listViewController.view.frame = self.view.bounds;
    self.listViewController.view.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    [self.view addSubview:self.listViewController.view];
    [self.listViewController didMoveToParentViewController:self];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
}

- (void)createNewConversation {
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
            [self openChatWithRecord:record conversation:conversation];
        }
    }];
}

- (void)openChatWithRecord:(CKTConversationRecord *)record conversation:(id)conversation {
    // Configure chat view
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
    
    // Register context providers directly on the chat view
    // Note: We need to ensure the view is loaded before accessing chatView
    dispatch_async(dispatch_get_main_queue(), ^{
        // Load the view if needed to ensure chatView is available
        [chatVC loadViewIfNeeded];
        
        if (@available(iOS 15.0, *)) {
            NoteContextProvider *noteProvider = [[NoteContextProvider alloc] init];
            chatVC.chatView.inputView.contextProviders = @[noteProvider];
            chatVC.chatView.inputView.contextPickerEnabled = YES;
            chatVC.chatView.inputView.contextPickerMaxItems = 3;
        }
        [self.navigationController pushViewController:chatVC animated:YES];
    });
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
    // Load the conversation and open chat
    [self.coordinator conversationWithSessionId:record.sessionId
                                     completion:^(CKTConversationRecord *loadedRecord, id conversation, NSError *error) {
        if (error || !loadedRecord || !conversation) {
            [self showAlertWithTitle:@"Error" message:@"Failed to load conversation"];
            return;
        }
        
        [self openChatWithRecord:loadedRecord conversation:conversation];
    }];
}

- (void)conversationListViewControllerDidRequestNewConversation:(ChatKitConversationListViewController *)controller {
    [self createNewConversation];
}

@end
