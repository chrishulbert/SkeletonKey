//
//  Groups.h
//  Passwords
//
//  Created by Chris Hulbert on 14/02/12.
//  Copyright (c) 2012 Splinter Software. All rights reserved.
//

#import <Foundation/Foundation.h>

@class Group;

@interface Groups : NSObject

@property(strong) NSArray* groups;

+ (Groups*)i;
- (void)addGroup:(Group*)g;
- (void)load;
- (void)saveSortOrder;
- (void)deleteGroup:(Group*)g;
- (void)makeAtLeastOneGroup;
- (Group*)groupById:(int)id;

@end
