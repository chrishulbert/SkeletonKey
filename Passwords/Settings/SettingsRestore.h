//
//  SettingsRestore.h
//  Passwords
//
//  Created by Chris Hulbert on 9/03/12.
//  Copyright (c) 2012 Splinter Software. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface SettingsRestore : UIViewController<UIActionSheetDelegate>

@property(weak) IBOutlet UITextField* password;
@property(strong) NSString* backupYmd; //eg 'y-m-d'

@end
