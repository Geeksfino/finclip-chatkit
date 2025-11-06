//
//  DrawerViewController.m
//  AI-Bank-OC
//
//  Side drawer menu displaying navigation options and settings
//

#import "DrawerViewController.h"
#import "ConversationListViewController.h"

@interface DrawerViewController () <UITableViewDelegate, UITableViewDataSource>

@property (nonatomic, strong) UITableView *tableView;
@property (nonatomic, strong) NSArray<NSString *> *menuItems;

@end

@implementation DrawerViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.view.backgroundColor = [UIColor secondarySystemBackgroundColor];
    
    self.menuItems = @[@"Conversations", @"Settings", @"About"];
    
    [self setupTableView];
}

- (void)setupTableView {
    self.tableView = [[UITableView alloc] initWithFrame:self.view.bounds style:UITableViewStylePlain];
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    self.tableView.backgroundColor = [UIColor secondarySystemBackgroundColor];
    self.tableView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    [self.tableView registerClass:[UITableViewCell class] forCellReuseIdentifier:@"MenuCell"];
    [self.view addSubview:self.tableView];
}

#pragma mark - UITableViewDataSource

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.menuItems.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"MenuCell" forIndexPath:indexPath];
    cell.textLabel.text = self.menuItems[indexPath.row];
    cell.backgroundColor = [UIColor secondarySystemBackgroundColor];
    return cell;
}

#pragma mark - UITableViewDelegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    NSString *selectedItem = self.menuItems[indexPath.row];
    
    if ([selectedItem isEqualToString:@"Conversations"]) {
        [self showConversations];
    } else if ([selectedItem isEqualToString:@"Settings"]) {
        [self showSettings];
    } else if ([selectedItem isEqualToString:@"About"]) {
        [self showAbout];
    }
}

- (void)showConversations {
    // Navigate to conversations list
    ConversationListViewController *conversationsVC = [[ConversationListViewController alloc] init];
    UINavigationController *navController = [[UINavigationController alloc] initWithRootViewController:conversationsVC];
    [self presentViewController:navController animated:YES completion:nil];
}

- (void)showSettings {
    // Show settings
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Settings"
                                                                   message:@"Settings functionality coming soon"
                                                            preferredStyle:UIAlertControllerStyleAlert];
    [alert addAction:[UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:nil]];
    [self presentViewController:alert animated:YES completion:nil];
}

- (void)showAbout {
    // Show about
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"AI-Bank-OC"
                                                                   message:@"Objective-C demonstration of Finclip ChatKit framework\n\nVersion 1.0"
                                                            preferredStyle:UIAlertControllerStyleAlert];
    [alert addAction:[UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:nil]];
    [self presentViewController:alert animated:YES completion:nil];
}

@end


