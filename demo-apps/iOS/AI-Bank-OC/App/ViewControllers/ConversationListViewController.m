//
//  ConversationListViewController.m
//  AI-Bank-OC
//
//  View controller displaying list of conversations
//

#import "ConversationListViewController.h"
#import "ConversationRecord.h"

@interface ConversationListViewController () <UITableViewDelegate, UITableViewDataSource>

@property (nonatomic, strong) UITableView *tableView;
@property (nonatomic, strong) NSMutableArray<ConversationRecord *> *conversations;

@end

@implementation ConversationListViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.title = @"Conversations";
    self.view.backgroundColor = [UIColor systemBackgroundColor];
    
    self.conversations = [NSMutableArray array];
    
    [self setupTableView];
    [self setupNavigationBar];
}

- (void)setupTableView {
    self.tableView = [[UITableView alloc] initWithFrame:self.view.bounds style:UITableViewStylePlain];
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    self.tableView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    [self.tableView registerClass:[UITableViewCell class] forCellReuseIdentifier:@"ConversationCell"];
    [self.view addSubview:self.tableView];
}

- (void)setupNavigationBar {
    UIBarButtonItem *closeButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemClose
                                                                                 target:self
                                                                                 action:@selector(closeButtonTapped)];
    self.navigationItem.rightBarButtonItem = closeButton;
}

- (void)closeButtonTapped {
    [self dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - UITableViewDataSource

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.conversations.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"ConversationCell" forIndexPath:indexPath];
    ConversationRecord *conversation = self.conversations[indexPath.row];
    cell.textLabel.text = conversation.title;
    return cell;
}

#pragma mark - UITableViewDelegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    // Handle conversation selection
}

@end


