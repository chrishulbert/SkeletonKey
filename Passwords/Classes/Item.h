//
//  Item.h
//  Passwords
//
//  Created by Chris Hulbert on 23/02/12.
//  Copyright (c) 2012 Splinter Software. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface Item : NSObject

@property(assign) int id;
@property(strong) NSString* name;
@property(assign) int groupId;
@property(strong) NSArray* fields;
@property(strong) NSString* notes;

- (NSString*)filePath;
- (void)save;
+ (Item*)loadItemById:(int)id;
- (void)deleteFile;

@end
