//
//  GroupChooser.h
//  Passwords
//
//  Created by Chris Hulbert on 22/02/12.
//  Copyright (c) 2012 Splinter Software. All rights reserved.
//

#import <UIKit/UIKit.h>

@class Group;

typedef void(^GroupChooserSuccess)(Group* g);

@interface GroupChooser : UITableViewController

@property(strong) Group* selectedGroup;
@property(copy) GroupChooserSuccess success;

@end
