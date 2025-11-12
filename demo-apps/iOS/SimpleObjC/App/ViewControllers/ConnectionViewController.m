//
//  ConnectionViewController.m
//  SimpleChatObjC
//
//  Connection screen for SimpleChatObjC
//

#import "ConnectionViewController.h"
#import "ConversationListViewController.h"
#import <FinClipChatKit/FinClipChatKit-Swift.h>

@interface ConnectionViewController () <CKTChatKitCoordinatorDelegate>

@property (nonatomic, strong) CKTChatKitCoordinator *coordinator;
@property (nonatomic, strong) UILabel *titleLabel;
@property (nonatomic, strong) UILabel *serverHintLabel;
@property (nonatomic, strong) UIButton *connectButton;
@property (nonatomic, strong) UILabel *statusLabel;

@end

@implementation ConnectionViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self setupUI];
}

- (void)setupUI {
    self.view.backgroundColor = UIColor.systemBackgroundColor;
    self.title = @"Connect";
    
    // Title label
    self.titleLabel = [[UILabel alloc] init];
    self.titleLabel.text = @"SimpleChatObjC";
    self.titleLabel.font = [UIFont systemFontOfSize:28 weight:UIFontWeightBold];
    self.titleLabel.textAlignment = NSTextAlignmentCenter;
    self.titleLabel.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addSubview:self.titleLabel];
    
    // Server hint label
    self.serverHintLabel = [[UILabel alloc] init];
    self.serverHintLabel.text = @"Connecting to: http://127.0.0.1:3000/agent";
    self.serverHintLabel.font = [UIFont systemFontOfSize:14];
    self.serverHintLabel.textColor = UIColor.secondaryLabelColor;
    self.serverHintLabel.textAlignment = NSTextAlignmentCenter;
    self.serverHintLabel.numberOfLines = 0;
    self.serverHintLabel.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addSubview:self.serverHintLabel];
    
    // Connect button
    UIButtonConfiguration *buttonConfig = [UIButtonConfiguration filledButtonConfiguration];
    buttonConfig.title = @"Connect";
    buttonConfig.cornerStyle = UIButtonConfigurationCornerStyleMedium;
    self.connectButton = [UIButton buttonWithConfiguration:buttonConfig primaryAction:nil];
    [self.connectButton addTarget:self 
                           action:@selector(connectTapped)
                 forControlEvents:UIControlEventTouchUpInside];
    self.connectButton.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addSubview:self.connectButton];
    
    // Status label
    self.statusLabel = [[UILabel alloc] init];
    self.statusLabel.text = @"Ready to connect";
    self.statusLabel.font = [UIFont systemFontOfSize:14];
    self.statusLabel.textColor = UIColor.secondaryLabelColor;
    self.statusLabel.textAlignment = NSTextAlignmentCenter;
    self.statusLabel.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addSubview:self.statusLabel];
    
    // Layout constraints
    [NSLayoutConstraint activateConstraints:@[
        [self.titleLabel.topAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.topAnchor constant:60],
        [self.titleLabel.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor constant:20],
        [self.titleLabel.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor constant:-20],
        
        [self.serverHintLabel.topAnchor constraintEqualToAnchor:self.titleLabel.bottomAnchor constant:40],
        [self.serverHintLabel.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor constant:40],
        [self.serverHintLabel.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor constant:-40],
        
        [self.connectButton.topAnchor constraintEqualToAnchor:self.serverHintLabel.bottomAnchor constant:30],
        [self.connectButton.centerXAnchor constraintEqualToAnchor:self.view.centerXAnchor],
        [self.connectButton.widthAnchor constraintEqualToConstant:200],
        [self.connectButton.heightAnchor constraintEqualToConstant:50],
        
        [self.statusLabel.topAnchor constraintEqualToAnchor:self.connectButton.bottomAnchor constant:20],
        [self.statusLabel.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor constant:20],
        [self.statusLabel.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor constant:-20]
    ]];
}

- (void)connectTapped {
    self.connectButton.enabled = NO;
    self.statusLabel.text = @"Connecting...";
    
    // Initialize SDK coordinator with default configuration
    NSURL *serverURL = [NSURL URLWithString:@"http://127.0.0.1:3000/agent"];
    CKTCoordinatorConfig *config = [[CKTCoordinatorConfig alloc] initWithServerURL:serverURL
                                                                             userId:@"demo-user"
                                                                           deviceId:nil];
    config.storageMode = CKTStorageModePersistent;
    
    self.coordinator = [[CKTChatKitCoordinator alloc] initWithConfig:config];
    self.coordinator.delegate = self;
    
    // Navigate to conversation list
    ConversationListViewController *listVC = [[ConversationListViewController alloc] initWithSDKCoordinator:self.coordinator];
    listVC.autoCreateConversation = YES;
    [self.navigationController pushViewController:listVC animated:YES];
    
    self.connectButton.enabled = YES;
}

#pragma mark - CKTChatKitCoordinatorDelegate

- (void)chatKitCoordinator:(CKTChatKitCoordinator *)coordinator didChangeState:(NSString *)state {
    dispatch_async(dispatch_get_main_queue(), ^{
        self.statusLabel.text = state;
    });
}

- (void)chatKitCoordinator:(CKTChatKitCoordinator *)coordinator didEncounterError:(NSError *)error {
    dispatch_async(dispatch_get_main_queue(), ^{
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Connection Error"
                                                                       message:error.localizedDescription
                                                                preferredStyle:UIAlertControllerStyleAlert];
        [alert addAction:[UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:nil]];
        [self presentViewController:alert animated:YES completion:nil];
    });
}

@end

