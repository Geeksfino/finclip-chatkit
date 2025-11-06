//
//  ChatViewController.m
//  AI-Bank-OC
//
//  Chat view controller demonstrating ChatKit usage in Objective-C
//
//  This view controller demonstrates how to integrate the Finclip ChatKit
//  framework in an Objective-C project. It shows:
//  - Embedding the ChatKit chat view
//  - Managing conversation state
//  - Handling agent messages and responses
//

#import "ChatViewController.h"
#import "RuntimeCoordinator.h"
@import FinClipChatKit;

@interface ChatViewController ()

@property (nonatomic, strong) RuntimeCoordinator *runtimeCoordinator;
@property (nonatomic, strong) UIView *chatView;  // This would be the actual ChatKit view
@property (nonatomic, strong) UITextView *messagesTextView;
@property (nonatomic, strong) UITextField *inputTextField;
@property (nonatomic, strong) UIButton *sendButton;
@property (nonatomic, strong) UIView *inputContainerView;

@end

@implementation ChatViewController

- (instancetype)initWithRuntimeCoordinator:(RuntimeCoordinator *)coordinator {
    self = [super init];
    if (self) {
        _runtimeCoordinator = coordinator;
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.view.backgroundColor = [UIColor systemBackgroundColor];
    
    // Setup ChatKit integration
    [self setupChatKitView];
    
    // Setup input UI
    [self setupInputUI];
    
    // Setup keyboard handling
    [self setupKeyboardNotifications];
}

- (void)setupChatKitView {
    // Initialize ChatKit chat view
    // In a real implementation, this would use ChatKit's view component
    // For demonstration purposes, we're using a UITextView
    
    self.messagesTextView = [[UITextView alloc] init];
    self.messagesTextView.translatesAutoresizingMaskIntoConstraints = NO;
    self.messagesTextView.editable = NO;
    self.messagesTextView.font = [UIFont systemFontOfSize:16];
    self.messagesTextView.backgroundColor = [UIColor secondarySystemBackgroundColor];
    [self.view addSubview:self.messagesTextView];
    
    // Layout constraints
    [NSLayoutConstraint activateConstraints:@[
        [self.messagesTextView.topAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.topAnchor],
        [self.messagesTextView.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor],
        [self.messagesTextView.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor]
    ]];
}

- (void)setupInputUI {
    // Input container
    self.inputContainerView = [[UIView alloc] init];
    self.inputContainerView.translatesAutoresizingMaskIntoConstraints = NO;
    self.inputContainerView.backgroundColor = [UIColor systemBackgroundColor];
    [self.view addSubview:self.inputContainerView];
    
    // Text input field
    self.inputTextField = [[UITextField alloc] init];
    self.inputTextField.translatesAutoresizingMaskIntoConstraints = NO;
    self.inputTextField.placeholder = @"Type a message...";
    self.inputTextField.borderStyle = UITextBorderStyleRoundedRect;
    self.inputTextField.returnKeyType = UIReturnKeySend;
    [self.inputTextField addTarget:self action:@selector(sendButtonTapped) forControlEvents:UIControlEventEditingDidEndOnExit];
    [self.inputContainerView addSubview:self.inputTextField];
    
    // Send button
    self.sendButton = [UIButton buttonWithType:UIButtonTypeSystem];
    self.sendButton.translatesAutoresizingMaskIntoConstraints = NO;
    [self.sendButton setTitle:@"Send" forState:UIControlStateNormal];
    [self.sendButton addTarget:self action:@selector(sendButtonTapped) forControlEvents:UIControlEventTouchUpInside];
    [self.inputContainerView addSubview:self.sendButton];
    
    // Layout constraints
    [NSLayoutConstraint activateConstraints:@[
        // Input container
        [self.inputContainerView.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor],
        [self.inputContainerView.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor],
        [self.inputContainerView.bottomAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.bottomAnchor],
        [self.inputContainerView.heightAnchor constraintEqualToConstant:60],
        
        // Messages text view bottom
        [self.messagesTextView.bottomAnchor constraintEqualToAnchor:self.inputContainerView.topAnchor],
        
        // Text field
        [self.inputTextField.leadingAnchor constraintEqualToAnchor:self.inputContainerView.leadingAnchor constant:16],
        [self.inputTextField.centerYAnchor constraintEqualToAnchor:self.inputContainerView.centerYAnchor],
        [self.inputTextField.trailingAnchor constraintEqualToAnchor:self.sendButton.leadingAnchor constant:-8],
        
        // Send button
        [self.sendButton.trailingAnchor constraintEqualToAnchor:self.inputContainerView.trailingAnchor constant:-16],
        [self.sendButton.centerYAnchor constraintEqualToAnchor:self.inputContainerView.centerYAnchor],
        [self.sendButton.widthAnchor constraintEqualToConstant:60]
    ]];
}

- (void)setupKeyboardNotifications {
    [[NSNotificationCenter defaultCenter] addObserver:self
                                           selector:@selector(keyboardWillShow:)
                                               name:UIKeyboardWillShowNotification
                                             object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                           selector:@selector(keyboardWillHide:)
                                               name:UIKeyboardWillHideNotification
                                             object:nil];
}

- (void)sendButtonTapped {
    NSString *message = self.inputTextField.text;
    if (message.length > 0) {
        [self sendMessage:message];
        self.inputTextField.text = @"";
    }
}

- (void)sendMessage:(NSString *)message {
    // Add user message to display
    NSString *currentText = self.messagesTextView.text ?: @"";
    NSString *userMessage = [NSString stringWithFormat:@"You: %@\n\n", message];
    self.messagesTextView.text = [currentText stringByAppendingString:userMessage];
    
    // Scroll to bottom
    [self scrollToBottom];
    
    // Send to ChatKit runtime coordinator
    [self.runtimeCoordinator sendMessage:message completion:^(NSString *response, NSError *error) {
        dispatch_async(dispatch_get_main_queue(), ^{
            if (error) {
                NSString *errorText = [NSString stringWithFormat:@"Error: %@\n\n", error.localizedDescription];
                self.messagesTextView.text = [self.messagesTextView.text stringByAppendingString:errorText];
            } else {
                NSString *agentMessage = [NSString stringWithFormat:@"Agent: %@\n\n", response];
                self.messagesTextView.text = [self.messagesTextView.text stringByAppendingString:agentMessage];
            }
            [self scrollToBottom];
        });
    }];
}

- (void)scrollToBottom {
    if (self.messagesTextView.text.length > 0) {
        NSRange bottom = NSMakeRange(self.messagesTextView.text.length - 1, 1);
        [self.messagesTextView scrollRangeToVisible:bottom];
    }
}

- (void)keyboardWillShow:(NSNotification *)notification {
    NSDictionary *userInfo = notification.userInfo;
    CGRect keyboardFrame = [userInfo[UIKeyboardFrameEndUserInfoKey] CGRectValue];
    CGFloat keyboardHeight = keyboardFrame.size.height;
    
    [UIView animateWithDuration:0.3 animations:^{
        self.inputContainerView.transform = CGAffineTransformMakeTranslation(0, -keyboardHeight);
    }];
}

- (void)keyboardWillHide:(NSNotification *)notification {
    [UIView animateWithDuration:0.3 animations:^{
        self.inputContainerView.transform = CGAffineTransformIdentity;
    }];
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

@end


