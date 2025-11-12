//
//  SceneDelegate.m
//  SimpleChatObjC
//
//  Scene lifecycle management - Simplified to use high-level ChatKit API directly
//

#import "SceneDelegate.h"
#import "ConversationListViewController.h"
#import <FinClipChatKit/FinClipChatKit-Swift.h>

@interface SceneDelegate ()
@property (nonatomic, strong) CKTChatKitCoordinator *coordinator;
@end

@implementation SceneDelegate

- (void)scene:(UIScene *)scene willConnectToSession:(UISceneSession *)session options:(UISceneConnectionOptions *)connectionOptions {
    if (![scene isKindOfClass:[UIWindowScene class]]) {
        return;
    }
    
    UIWindowScene *windowScene = (UIWindowScene *)scene;
    self.window = [[UIWindow alloc] initWithWindowScene:windowScene];
    
    // Initialize ChatKitCoordinator directly - no wrapper needed!
    NSURL *serverURL = [NSURL URLWithString:@"http://127.0.0.1:3000/agent"];
    CKTCoordinatorConfig *config = [[CKTCoordinatorConfig alloc] initWithServerURL:serverURL
                                                                             userId:@"demo-user"
                                                                           deviceId:nil];
    config.storageMode = CKTStorageModePersistent;
    self.coordinator = [[CKTChatKitCoordinator alloc] initWithConfig:config];
    
    // Create conversation list with navigation
    ConversationListViewController *listVC = [[ConversationListViewController alloc] initWithCoordinator:self.coordinator];
    UINavigationController *navController = [[UINavigationController alloc] initWithRootViewController:listVC];
    
    self.window.rootViewController = navController;
    [self.window makeKeyAndVisible];
}

- (void)sceneDidDisconnect:(UIScene *)scene {
    // Called as the scene is being released by the system
}

- (void)sceneDidBecomeActive:(UIScene *)scene {
    // Called when the scene has moved from an inactive state to an active state
}

- (void)sceneWillResignActive:(UIScene *)scene {
    // Called when the scene will move from an active state to an inactive state
}

- (void)sceneWillEnterForeground:(UIScene *)scene {
    // Called as the scene transitions from the background to the foreground
}

- (void)sceneDidEnterBackground:(UIScene *)scene {
    // Called as the scene transitions from the foreground to the background
}

@end
