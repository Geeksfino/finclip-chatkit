//
//  NoteContextProvider.m
//  SimpleObjC
//
//  Example Objective-C context provider implementation
//

#import "NoteContextProvider.h"

// MARK: - Note Context Item

/// Internal class representing a note context item
@interface NoteContextItem : FinConvoContextItem <FinConvoContextItemEncoding, FinConvoContextItemPreview>

@property (nonatomic, strong) NSString *noteText;
@property (nonatomic, strong) NSDate *timestamp;

- (instancetype)initWithText:(NSString *)text;

@end

@implementation NoteContextItem

- (instancetype)initWithText:(NSString *)text {
    self = [super init];
    if (self) {
        _noteText = text ?: @"";
        _timestamp = [NSDate date];
        self.contextId = [[NSUUID UUID] UUIDString];
        self.contextType = @"note";
        self.providerId = @"simpleobjc.note";
        self.displayName = @"Note";
        self.previewText = [self truncatedPreview];
        
        // Set encoding handler to self so the framework uses our encoding methods
        // This is required for the context item to be properly encoded and sent to the backend
        self.encodingHandler = self;
        
        // Set preview handler to self so the framework uses our custom preview view
        self.previewHandler = self;
    }
    return self;
}

- (NSString *)truncatedPreview {
    if (self.noteText.length <= 40) {
        return self.noteText;
    }
    return [[self.noteText substringToIndex:37] stringByAppendingString:@"..."];
}

// MARK: - FinConvoContextItemEncoding

- (NSData *)encodeForTransport:(NSError **)error {
    NSDictionary *payload = @{
        @"text": self.noteText,
        @"timestamp": @([self.timestamp timeIntervalSince1970]),
        @"type": @"note"
    };
    
    NSError *jsonError = nil;
    NSData *data = [NSJSONSerialization dataWithJSONObject:payload
                                                   options:NSJSONWritingSortedKeys
                                                     error:&jsonError];
    if (jsonError && error) {
        *error = jsonError;
    }
    return data;
}

- (FinConvoContextEncoding)encodingRepresentation {
    return FinConvoContextEncodingJSON;
}

- (NSDictionary<NSString *, NSString *> *)encodingMetadata {
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    formatter.dateStyle = NSDateFormatterMediumStyle;
    formatter.timeStyle = NSDateFormatterShortStyle;
    
    return @{
        @"provider": self.providerId,
        @"type": @"text_note",
        @"timestamp": [formatter stringFromDate:self.timestamp],
        @"preview": self.previewText
    };
}

// MARK: - FinConvoContextItemPreview

- (UIView *)createPreviewViewWithRemoveHandler:(void (^)(void))onRemove {
    // Create container view
    UIView *container = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 200, 40)];
    container.backgroundColor = [UIColor systemPurpleColor];
    container.alpha = 0.15;
    container.layer.cornerRadius = 8;
    container.layer.borderWidth = 1;
    container.layer.borderColor = [UIColor systemPurpleColor].CGColor;
    
    // Icon label
    UILabel *iconLabel = [[UILabel alloc] initWithFrame:CGRectMake(8, 10, 20, 20)];
    iconLabel.text = @"📝";
    iconLabel.font = [UIFont systemFontOfSize:16];
    [container addSubview:iconLabel];
    
    // Text label
    UILabel *textLabel = [[UILabel alloc] initWithFrame:CGRectMake(32, 0, 140, 40)];
    textLabel.text = self.previewText;
    textLabel.font = [UIFont systemFontOfSize:13];
    textLabel.textColor = [UIColor labelColor];
    textLabel.numberOfLines = 1;
    textLabel.lineBreakMode = NSLineBreakByTruncatingTail;
    [container addSubview:textLabel];
    
    // Remove button
    UIButton *removeButton = [UIButton buttonWithType:UIButtonTypeSystem];
    removeButton.frame = CGRectMake(175, 10, 20, 20);
    [removeButton setTitle:@"✕" forState:UIControlStateNormal];
    removeButton.titleLabel.font = [UIFont systemFontOfSize:14 weight:UIFontWeightMedium];
    [removeButton addAction:[UIAction actionWithHandler:^(UIAction * _Nonnull action) {
        onRemove();
    }] forControlEvents:UIControlEventTouchUpInside];
    [container addSubview:removeButton];
    
    return container;
}

@end

// MARK: - Note Collector View

@interface NoteCollectorView : UIView

@property (nonatomic, copy) void (^onConfirm)(FinConvoContextItem * _Nullable);

@end

@implementation NoteCollectorView {
    UITextView *_textView;
    UIButton *_confirmButton;
}

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        [self setupUI];
    }
    return self;
}

- (void)setupUI {
    self.backgroundColor = [UIColor systemBackgroundColor];
    
    // Title label
    UILabel *titleLabel = [[UILabel alloc] init];
    titleLabel.text = @"Add a Note";
    titleLabel.font = [UIFont preferredFontForTextStyle:UIFontTextStyleHeadline];
    titleLabel.translatesAutoresizingMaskIntoConstraints = NO;
    [self addSubview:titleLabel];
    
    // Text view
    _textView = [[UITextView alloc] init];
    _textView.font = [UIFont systemFontOfSize:16];
    _textView.layer.borderWidth = 1;
    _textView.layer.borderColor = [UIColor separatorColor].CGColor;
    _textView.layer.cornerRadius = 8;
    _textView.textContainerInset = UIEdgeInsetsMake(12, 8, 12, 8);
    _textView.translatesAutoresizingMaskIntoConstraints = NO;
    [self addSubview:_textView];
    
    // Confirm button
    _confirmButton = [UIButton buttonWithType:UIButtonTypeSystem];
    [_confirmButton setTitle:@"Attach Note" forState:UIControlStateNormal];
    _confirmButton.titleLabel.font = [UIFont preferredFontForTextStyle:UIFontTextStyleHeadline];
    _confirmButton.backgroundColor = [UIColor systemBlueColor];
    [_confirmButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    _confirmButton.layer.cornerRadius = 12;
    _confirmButton.translatesAutoresizingMaskIntoConstraints = NO;
    [_confirmButton addTarget:self action:@selector(confirmTapped) forControlEvents:UIControlEventTouchUpInside];
    [self addSubview:_confirmButton];
    
    // Layout
    [NSLayoutConstraint activateConstraints:@[
        [titleLabel.topAnchor constraintEqualToAnchor:self.topAnchor constant:20],
        [titleLabel.leadingAnchor constraintEqualToAnchor:self.leadingAnchor constant:20],
        [titleLabel.trailingAnchor constraintEqualToAnchor:self.trailingAnchor constant:-20],
        
        [_textView.topAnchor constraintEqualToAnchor:titleLabel.bottomAnchor constant:16],
        [_textView.leadingAnchor constraintEqualToAnchor:self.leadingAnchor constant:20],
        [_textView.trailingAnchor constraintEqualToAnchor:self.trailingAnchor constant:-20],
        [_textView.heightAnchor constraintEqualToConstant:120],
        
        [_confirmButton.topAnchor constraintEqualToAnchor:_textView.bottomAnchor constant:16],
        [_confirmButton.leadingAnchor constraintEqualToAnchor:self.leadingAnchor constant:20],
        [_confirmButton.trailingAnchor constraintEqualToAnchor:self.trailingAnchor constant:-20],
        [_confirmButton.heightAnchor constraintEqualToConstant:50],
        [_confirmButton.bottomAnchor constraintEqualToAnchor:self.bottomAnchor constant:-20]
    ]];
    
    // Auto-focus text view
    dispatch_async(dispatch_get_main_queue(), ^{
        [self->_textView becomeFirstResponder];
    });
}

- (void)confirmTapped {
    NSString *text = [_textView.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    if (text.length == 0) {
        // Cancel if empty
        if (self.onConfirm) {
            self.onConfirm(nil);
        }
        return;
    }
    
    NoteContextItem *item = [[NoteContextItem alloc] initWithText:text];
    if (self.onConfirm) {
        self.onConfirm(item);
    }
}

@end

// MARK: - Note Detail View

@interface NoteDetailView : UIView

@property (nonatomic, copy) void (^onDismiss)(void);

- (instancetype)initWithNoteText:(NSString *)noteText timestamp:(NSDate *)timestamp;

@end

@implementation NoteDetailView {
    UILabel *_titleLabel;
    UILabel *_textLabel;
    UILabel *_timestampLabel;
    UIButton *_closeButton;
}

- (instancetype)initWithNoteText:(NSString *)noteText timestamp:(NSDate *)timestamp {
    self = [super initWithFrame:CGRectZero];
    if (self) {
        [self setupUI];
        [self configureWithNoteText:noteText timestamp:timestamp];
    }
    return self;
}

- (void)setupUI {
    self.backgroundColor = [UIColor systemBackgroundColor];
    
    _titleLabel = [[UILabel alloc] init];
    _titleLabel.text = @"Note";
    _titleLabel.font = [UIFont preferredFontForTextStyle:UIFontTextStyleTitle1];
    _titleLabel.translatesAutoresizingMaskIntoConstraints = NO;
    [self addSubview:_titleLabel];
    
    _timestampLabel = [[UILabel alloc] init];
    _timestampLabel.font = [UIFont preferredFontForTextStyle:UIFontTextStyleCaption1];
    _timestampLabel.textColor = [UIColor secondaryLabelColor];
    _timestampLabel.translatesAutoresizingMaskIntoConstraints = NO;
    [self addSubview:_timestampLabel];
    
    _textLabel = [[UILabel alloc] init];
    _textLabel.font = [UIFont preferredFontForTextStyle:UIFontTextStyleBody];
    _textLabel.numberOfLines = 0;
    _textLabel.translatesAutoresizingMaskIntoConstraints = NO;
    [self addSubview:_textLabel];
    
    _closeButton = [UIButton buttonWithType:UIButtonTypeSystem];
    [_closeButton setTitle:@"Close" forState:UIControlStateNormal];
    _closeButton.titleLabel.font = [UIFont preferredFontForTextStyle:UIFontTextStyleHeadline];
    _closeButton.translatesAutoresizingMaskIntoConstraints = NO;
    [_closeButton addTarget:self action:@selector(closeTapped) forControlEvents:UIControlEventTouchUpInside];
    [self addSubview:_closeButton];
    
    [NSLayoutConstraint activateConstraints:@[
        [_titleLabel.topAnchor constraintEqualToAnchor:self.topAnchor constant:24],
        [_titleLabel.leadingAnchor constraintEqualToAnchor:self.leadingAnchor constant:20],
        [_titleLabel.trailingAnchor constraintEqualToAnchor:self.trailingAnchor constant:-20],
        
        [_timestampLabel.topAnchor constraintEqualToAnchor:_titleLabel.bottomAnchor constant:8],
        [_timestampLabel.leadingAnchor constraintEqualToAnchor:_titleLabel.leadingAnchor],
        [_timestampLabel.trailingAnchor constraintEqualToAnchor:_titleLabel.trailingAnchor],
        
        [_textLabel.topAnchor constraintEqualToAnchor:_timestampLabel.bottomAnchor constant:24],
        [_textLabel.leadingAnchor constraintEqualToAnchor:self.leadingAnchor constant:20],
        [_textLabel.trailingAnchor constraintEqualToAnchor:self.trailingAnchor constant:-20],
        
        [_closeButton.topAnchor constraintEqualToAnchor:_textLabel.bottomAnchor constant:32],
        [_closeButton.centerXAnchor constraintEqualToAnchor:self.centerXAnchor],
        [_closeButton.bottomAnchor constraintEqualToAnchor:self.bottomAnchor constant:-24]
    ]];
}

- (void)configureWithNoteText:(NSString *)noteText timestamp:(NSDate *)timestamp {
    _textLabel.text = noteText;
    
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    formatter.dateStyle = NSDateFormatterMediumStyle;
    formatter.timeStyle = NSDateFormatterShortStyle;
    _timestampLabel.text = [formatter stringFromDate:timestamp];
}

- (void)closeTapped {
    if (self.onDismiss) {
        self.onDismiss();
    }
}

@end

// MARK: - NoteContextProvider Implementation

@implementation NoteContextProvider

- (NSString *)providerId {
    return @"simpleobjc.note";
}

- (NSString *)displayName {
    return @"Note";
}

- (NSString *)iconName {
    return @"note.text";
}

- (BOOL)isAvailable {
    return YES;
}

- (NSInteger)displayPriority {
    return 50; // Lower priority than default providers
}

- (NSInteger)maximumAttachmentCount {
    return 1; // Only one note at a time
}

- (BOOL)shouldUseContainerPanel {
    return YES; // Use the sliding panel container
}

- (UIView *)createCollectorViewWithConfirmHandler:(void (^)(FinConvoContextItem * _Nullable))onConfirm {
    NoteCollectorView *collector = [[NoteCollectorView alloc] init];
    collector.onConfirm = onConfirm;
    return collector;
}

- (UIView *)createDetailViewForItem:(FinConvoContextItem *)item dismissHandler:(void (^)(void))onDismiss {
    // Check if this is our note item by type or provider ID
    NoteContextItem *noteItem = nil;
    if ([item isKindOfClass:[NoteContextItem class]]) {
        noteItem = (NoteContextItem *)item;
    } else if ([item.providerId isEqualToString:@"simpleobjc.note"]) {
        // Fallback: try to extract data from metadata or contextData
        // For this example, we'll require the item to be a NoteContextItem
        return nil;
    } else {
        return nil;
    }
    
    NoteDetailView *detailView = [[NoteDetailView alloc] initWithNoteText:noteItem.noteText
                                                                 timestamp:noteItem.timestamp];
    detailView.onDismiss = onDismiss;
    return detailView;
}

- (NSString *)localizedDescriptionForItem:(FinConvoContextItem *)item {
    if ([item isKindOfClass:[NoteContextItem class]]) {
        NoteContextItem *noteItem = (NoteContextItem *)item;
        return noteItem.noteText;
    }
    return item.previewText ?: item.displayName;
}

- (void)presentContextCollectorFromViewController:(UIViewController *)viewController
                                        completion:(void (^)(FinConvoContextItem * _Nullable))completion {
    // This method is not used when shouldUseContainerPanel returns YES
    // The framework will use createCollectorViewWithConfirmHandler: instead
    if (completion) {
        completion(nil);
    }
}

@end

