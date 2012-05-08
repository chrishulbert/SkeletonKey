//
//  ViewItem.h
//  Passwords
//
//  Created by Chris Hulbert on 24/02/12.
//  Copyright (c) 2012 Splinter Software. All rights reserved.
//

#import <UIKit/UIKit.h>

@class Item;

@interface ViewItem : UITableViewController<UIActionSheetDelegate>

@property(strong) Item* item;

@end
