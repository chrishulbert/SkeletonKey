//
//  SettingsBackup.h
//  Passwords
//
//  Created by Chris Hulbert on 2/03/12.
//  Copyright (c) 2012 Splinter Software. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface SettingsBackup : UITableViewController<UIAlertViewDelegate>

@property(strong) NSString* backupYmd;
@property(strong) NSArray* groups;
@property(strong) NSArray* items;

@end
