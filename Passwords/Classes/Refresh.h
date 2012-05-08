//
//  Refresh.h
//  Passwords
//
//  Created by Chris Hulbert on 24/02/12.
//  Copyright (c) 2012 Splinter Software. All rights reserved.
//

#import <Foundation/Foundation.h>

#define refreshNotification @"refresh"
#define refreshItemsNotification @"refreshItems"
#define passwordNotification @"password"

@interface Refresh : NSObject

+ (void)sendRefresh;
+ (void)sendRefreshItemsNotGroups;
+ (void)passwordHasChanged;

@end
