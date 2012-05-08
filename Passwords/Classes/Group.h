//
//  Group.h
//  Passwords
//
//  Created by Chris Hulbert on 14/02/12.
//  Copyright (c) 2012 Splinter Software. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface Group : NSObject

@property(strong) NSString* name;
@property(strong) NSString* icon;
@property(assign) int hue;
@property(assign) int id;

+ (Group*)groupFromYamlDict:(NSDictionary*)d;
- (UIColor*)colour;
- (void)save;
- (void)deleteFile;

@end
