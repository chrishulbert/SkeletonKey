//
//  SettingsGroupEdit.h
//  Passwords
//
//  Created by Chris Hulbert on 15/02/12.
//  Copyright (c) 2012 Splinter Software. All rights reserved.
//

#import <UIKit/UIKit.h>

@class Group;

@interface SettingsGroupEdit : UIViewController<UITextFieldDelegate> {
    NSMutableDictionary* iconButtonFilenames;
    UIScrollView* scroll;
}

@property(strong) Group* originalGroup;
@property(strong) Group* group;
@property(assign) IBOutlet UITextField* name;

@end
