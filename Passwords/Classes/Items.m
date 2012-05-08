//
//  Items.m
//  Passwords
//
//  Created by Chris Hulbert on 23/02/12.
//  Copyright (c) 2012 Splinter Software. All rights reserved.
//

#import "Items.h"
#import "Group.h"
#import "ConciseKit.h"
#import "MyYaml.h"
#import "Groups.h"
#import "Item.h"

@implementation Items

+ (NSArray*)getItemsForGroup:(Group*)g {
    // The first group gets all the orphaned items, so are we that group?
    BOOL isFirst = g.id == [[[Groups i].groups objectAtIndex:0] id];
    NSMutableIndexSet* groupIds = nil;
    if (isFirst) {
        groupIds = [NSMutableIndexSet indexSet];
        for (Group* g in [Groups i].groups) {
            [groupIds addIndex:g.id];
        }
    }
    
    NSMutableArray* arr = [NSMutableArray array];
    NSArray* files = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:[$ documentPath] error:nil];
    for (NSString* file in files) {
        if ([file hasPrefix:@"item_"] && [file hasSuffix:@".yaml"]) {
            NSDictionary *dict = [file readDocumentsFileAsYaml];
            int groupId = [[dict $for:@"group_id"] intValue];
            if (groupId == g.id || (isFirst && ![groupIds containsIndex:groupId])) {
                NSString* name = [dict $for:@"name"];
                NSString* id = [dict $for:@"id"];
                if (name.length && id.intValue>0) {
                    [arr addObject:$arr(id, name)];
                }
            }
                
        }
    }
    
    [arr sortUsingComparator:^NSComparisonResult(id obj1, id obj2) {
        NSString* name1 = [obj1 $at:1];
        NSString* name2 = [obj2 $at:1];
        return [name1 caseInsensitiveCompare:name2];
    }];
    return arr;
}

// Are there any items at all?
+ (BOOL)areAnyItems {
    NSArray* files = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:[$ documentPath] error:nil];
    for (NSString* file in files) {
        if ([file hasPrefix:@"item_"] && [file hasSuffix:@".yaml"]) {
            return YES;
        }
    }
    return NO;
}

@end
