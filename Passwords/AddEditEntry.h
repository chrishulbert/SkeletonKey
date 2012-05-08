//
//  AddEditEntry.h
//  Passwords
//
//  Created by Chris Hulbert on 22/02/12.
//  Copyright (c) 2012 Splinter Software. All rights reserved.
//

#import <UIKit/UIKit.h>

@class Group, Item;

@interface AddEditEntry : UITableViewController<UIActionSheetDelegate>

@property(strong) Group* group;
@property(strong) Item* originalItem;

@end
