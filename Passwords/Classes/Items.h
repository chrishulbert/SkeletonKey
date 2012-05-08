//
//  Items.h
//  Passwords
//
//  Created by Chris Hulbert on 23/02/12.
//  Copyright (c) 2012 Splinter Software. All rights reserved.
//

#import <Foundation/Foundation.h>

@class Group;
@class Item;

@interface Items : NSObject

+ (NSArray*)getItemsForGroup:(Group*)g;
+ (BOOL)areAnyItems;

@end
