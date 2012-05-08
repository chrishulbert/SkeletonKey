//
//  GroupTable.h
//  Passwords
//
//  Created by Chris Hulbert on 20/02/12.
//  Copyright (c) 2012 Splinter Software. All rights reserved.
//

#import <UIKit/UIKit.h>

@class Group;

@interface GroupTable : UITableViewController<UIAlertViewDelegate>

@property(strong) Group* group;

@end
