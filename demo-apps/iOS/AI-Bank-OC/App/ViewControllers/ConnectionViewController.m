//
//  ConnectionViewController.m
//  AI-Bank-OC
//
//  View controller for configuring server connection settings
//

#import "ConnectionViewController.h"

@interface ConnectionViewController ()

@property (nonatomic, strong) UITextField *serverURLTextField;
@property (nonatomic, strong) UIButton *connectButton;
@property (nonatomic, strong) UILabel *statusLabel;

@end

@implementation ConnectionViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.title = @"Connection Settings";
    self.view.backgroundColor = [UIColor systemBackgroundColor];
    
    [self setupUI];
}

- (void)setupUI {
    // Server URL input
    UILabel *urlLabel = [[UILabel alloc] init];
    urlLabel.text = @"Server URL:";
    urlLabel.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addSubview:urlLabel];
    
    self.serverURLTextField = [[UITextField alloc] init];
    self.serverURLTextField.translatesAutoresizingMaskIntoConstraints = NO;
    self.serverURLTextField.placeholder = @"https://api.example.com";
    self.serverURLTextField.borderStyle = UITextBorderStyleRoundedRect;
    self.serverURLTextField.autocapitalizationType = UITextAutocapitalizationTypeNone;
    self.serverURLTextField.keyboardType = UIKeyboardTypeURL;
    [self.view addSubview:self.serverURLTextField];
    
    // Connect button
    self.connectButton = [UIButton buttonWithType:UIButtonTypeSystem];
    self.connectButton.translatesAutoresizingMaskIntoConstraints = NO;
    [self.connectButton setTitle:@"Test Connection" forState:UIControlStateNormal];
    [self.connectButton addTarget:self action:@selector(testConnection) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:self.connectButton];
    
    // Status label
    self.statusLabel = [[UILabel alloc] init];
    self.statusLabel.translatesAutoresizingMaskIntoConstraints = NO;
    self.statusLabel.textAlignment = NSTextAlignmentCenter;
    self.statusLabel.textColor = [UIColor secondaryLabelColor];
    self.statusLabel.numberOfLines = 0;
    [self.view addSubview:self.statusLabel];
    
    // Layout
    [NSLayoutConstraint activateConstraints:@[
        [urlLabel.topAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.topAnchor constant:32],
        [urlLabel.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor constant:20],
        [urlLabel.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor constant:-20],
        
        [self.serverURLTextField.topAnchor constraintEqualToAnchor:urlLabel.bottomAnchor constant:8],
        [self.serverURLTextField.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor constant:20],
        [self.serverURLTextField.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor constant:-20],
        [self.serverURLTextField.heightAnchor constraintEqualToConstant:44],
        
        [self.connectButton.topAnchor constraintEqualToAnchor:self.serverURLTextField.bottomAnchor constant:20],
        [self.connectButton.centerXAnchor constraintEqualToAnchor:self.view.centerXAnchor],
        [self.connectButton.widthAnchor constraintEqualToConstant:200],
        
        [self.statusLabel.topAnchor constraintEqualToAnchor:self.connectButton.bottomAnchor constant:20],
        [self.statusLabel.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor constant:20],
        [self.statusLabel.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor constant:-20]
    ]];
}

- (void)testConnection {
    NSString *urlString = self.serverURLTextField.text;
    
    if (urlString.length == 0) {
        self.statusLabel.text = @"Please enter a server URL";
        self.statusLabel.textColor = [UIColor systemRedColor];
        return;
    }
    
    self.statusLabel.text = @"Testing connection...";
    self.statusLabel.textColor = [UIColor secondaryLabelColor];
    
    // Simulate connection test
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        self.statusLabel.text = @"✓ Connection successful";
        self.statusLabel.textColor = [UIColor systemGreenColor];
    });
}

@end


