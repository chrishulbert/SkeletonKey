//
//  AppDelegate.m
//  Passwords
//
//  Created by Chris Hulbert on 14/02/12.
//  Copyright (c) 2012 Splinter Software. All rights reserved.
//

#import "AppDelegate.h"
#import "Groups.h"
#import "Group.h"
#import "SettingsRoot.h"
#import "ConciseKit.h"
#import "GroupTable.h"
#import "Password.h"
#import "DropboxSDK.h"
#import "Refresh.h"
#import "Backups.h"
#import "CHBgDropboxSync.h"
#import "Appirater.h"

@implementation AppDelegate

@synthesize window = _window;
@synthesize tabBarController = _tabBarController;

- (void)addFadingLaunchImage {
    // Have a launch image that includes the pass/pin entry textfield
    // Then have no animation if they go to the pass/pin entry screens
    // Or if no password, then slide down
    if (![Password passwordHasBeenSet]) {
        UIImageView* iv = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"Default"]];
        [self.window addSubview:iv];
        [UIView animateWithDuration:0.5 animations:^{
            iv.frame = CGRectOffset(iv.frame, 0, iv.frame.size.height);
        } completion:^(BOOL finished) {
            [iv removeFromSuperview];
        }];
    }
}

- (void)tapSettings {
    SettingsRoot* s = [[SettingsRoot alloc] initWithNibName:@"SettingsRoot" bundle:nil];
    UINavigationController* n = [[UINavigationController alloc] initWithRootViewController:s];
    n.modalTransitionStyle = UIModalTransitionStyleFlipHorizontal;
    [self.window.rootViewController presentModalViewController:n animated:YES];
}

+ (AppDelegate*)i {
    return (AppDelegate*)[[UIApplication sharedApplication] delegate];
}

- (NSArray*)makeTabs {
    // Make sure there's at least 1 group!
    [[Groups i] makeAtLeastOneGroup];
    
    NSMutableArray* tabs = [NSMutableArray array];
    for (Group* group in [Groups i].groups) {
        GroupTable* gt = [[GroupTable alloc] initWithNibName:@"GroupTable" bundle:nil];
        gt.title = group.name;
        gt.group = group;
        gt.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"tbar_settings"] style:(UIBarButtonItemStyleBordered) target:self action:@selector(tapSettings)];
                
        UINavigationController* n = [[UINavigationController alloc] initWithRootViewController:gt];
        n.title = group.name;
        n.tabBarItem.image = [UIImage imageNamed:group.icon];
        n.navigationBar.tintColor = group.colour;
        [tabs addObject:n];
    }
    return [NSArray arrayWithArray:tabs];
}

- (void)aboutToReturnFromSettings {
    // Re-create the tabs
    self.tabBarController.viewControllers = [self makeTabs];
}

- (void)receivedRefresh:(NSNotification*)n {
    NSLog(@"App delegate received refresh");
    self.tabBarController.viewControllers = [self makeTabs];
}

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    
    // Dropbox
    #warning todo You'll need to enter your own DB keys below
    DBSession* dbSession = [[DBSession alloc]
                            initWithAppKey:@"xxx"
                            appSecret:@"yyy"
                            root:kDBRootAppFolder]; // either kDBRootAppFolder or kDBRootDropbox
    [DBSession setSharedSession:dbSession];
    
    // So that later on, when i change to in-app-purchases, i can check this to see if they bought it beforehand
    // TODO remove this when going to IAP, and make the app free briefly before the IAP version comes out, so nobody buys the IAP version (or make the price change with the new version)
    [[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"boughtInitialUnlockedVersion"];
        
    // Styling
    [[UINavigationBar appearance] setBarStyle:UIBarStyleBlack];
    [[UINavigationBar appearance] setTitleTextAttributes:$dict([UIFont fontWithName:@"HelveticaNeue-Light" size:22], UITextAttributeFont)];
    [[UINavigationBar appearance] setTitleVerticalPositionAdjustment:-2 forBarMetrics:(UIBarMetricsDefault)];
    
    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    
    // Make the tab controller
    self.tabBarController = [[UITabBarController alloc] init];
    self.tabBarController.viewControllers = [self makeTabs];
    
    self.window.rootViewController = self.tabBarController;
    [self.window makeKeyAndVisible];
    
    // Listen for sync-pulled-new-password notifications. We want to subscribe to the refresh *after* the 'groups' has had a chance to register, so it can update first.
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(syncedNewPassword:) name:passwordNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(receivedRefresh:) name:refreshNotification object:nil];
                
    [Appirater appLaunched:YES];
    return YES;
}

// Dropbox
- (BOOL)application:(UIApplication *)application handleOpenURL:(NSURL *)url {
    if ([[DBSession sharedSession] handleOpenURL:url]) {
        if ([[DBSession sharedSession] isLinked]) {
            [Refresh sendRefresh]; // So the UI can update to reflect
            NSLog(@"App linked successfully!");
            // At this point you can start making API calls
            
            // Unused groups are handled thus: when syncing, if the password is different, it'll nuke the local files and pull everything down
            [CHBgDropboxSync clearLastSyncData];
            [CHBgDropboxSync start];
        }
        return YES;
    }
    // Add whatever other url handling code your app requires here
    return NO;
}

#pragma mark - Prompting for passwords

- (void)promptForPassword:(BOOL)hideKeyboard {
    // Pop up the 'enter password/pin' thing *only if* they've set a password yet, also keep into account enterfg vs becomeactive
    if ([Password passwordHasBeenSet]) {
        [self.window.rootViewController dismissModalViewControllerAnimated:NO]; // Close any modals just in case one's already open, because if so then the password entry wouldn't open. I think it's one-modal-at-a-time?
        [Password presentPinOrPasswordEntryModal:hideKeyboard];
    }
}

- (void)syncedNewPassword:(NSNotification*)n {
    [[Password i] appGoingToBackground]; // Drop the key
    [self promptForPassword:NO];
}

#pragma mark - Opening the app

// Called when returning to the app but not on startup
- (void)applicationWillEnterForeground:(UIApplication *)application {
    [Appirater appEnteredForeground:YES];
    //    NSLog(@"Will Enter FG");
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
}

// Gets called on startup and returning to the app
- (void)applicationDidBecomeActive:(UIApplication *)application {
    //    NSLog(@"Did become active");
    [Backups appLaunchBackup]; // Do a daily backup if one doesn't exist
    [CHBgDropboxSync start];   // Start the sync
    [self promptForPassword:NO];  // Ask for the password so it can re-generate the in-memory key
    [self addFadingLaunchImage]; // Make the launch image fade out
}

#pragma mark - Closing the app

- (void)applicationWillTerminate:(UIApplication *)application {
    [CHBgDropboxSync forceStopIfRunning];
    [[Password i] appGoingToBackground]; // Drop the key
    /*
     Called when the application is about to terminate.
     Save data if appropriate.
     See also applicationDidEnterBackground:.
     */
}


- (void)applicationWillResignActive:(UIApplication *)application {
    [CHBgDropboxSync forceStopIfRunning];
    [[Password i] appGoingToBackground]; // Drop the key
    [self promptForPassword:YES];
    /*
     Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
     Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
     */
}

- (void)applicationDidEnterBackground:(UIApplication *)application {
    [CHBgDropboxSync forceStopIfRunning];
    [[Password i] appGoingToBackground]; // Drop the key
    /*
     Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later. 
     If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
     */
}

@end
