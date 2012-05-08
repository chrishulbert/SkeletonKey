//
//  Refresh.m
//  Passwords
//
//  Created by Chris Hulbert on 24/02/12.
//  Copyright (c) 2012 Splinter Software. All rights reserved.
//

#import "Refresh.h"

@implementation Refresh

+ (void)sendRefresh {
    [[NSNotificationCenter defaultCenter] postNotificationName:refreshNotification object:nil];
}

+ (void)sendRefreshItemsNotGroups {
    [[NSNotificationCenter defaultCenter] postNotificationName:refreshItemsNotification object:nil];
}

// This is called by the syncer when it downloads a new password, so the app needs to prompt the user for a new key
+ (void)passwordHasChanged {
    [[NSNotificationCenter defaultCenter] postNotificationName:passwordNotification object:nil];
}

@end
