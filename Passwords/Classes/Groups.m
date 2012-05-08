//
//  Groups.m
//  Passwords
//
//  Created by Chris Hulbert on 14/02/12.
//  Copyright (c) 2012 Splinter Software. All rights reserved.
//

#import "Groups.h"
#import "Group.h"
#import "MyYaml.h"
#import "ConciseKit.h"
#import "Refresh.h"
#import "CHBgDropboxSync.h"

@implementation Groups

@synthesize groups;

+ (Groups*)i {
    static id instance=nil;
    if (!instance) {
        instance = [[Groups alloc] init];
    }
    return instance;
}

- (id)init {
    if (self=[super init]) {
        // Load from initial groups list
        [self load];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(receivedRefreshNotification:) name:refreshNotification object:nil];
    }
    return self;
}

- (void)receivedRefreshNotification:(NSNotification*)n {
    [self load];
}

- (void)deleteGroup:(Group*)g {
    [g deleteFile]; // Remove from disk
    // Now remove from memory
    NSMutableArray* arr = [NSMutableArray arrayWithArray:self.groups];
    [arr removeObject:g];
    self.groups = [NSArray arrayWithArray:arr];
}

- (void)addGroup:(Group*)g {
    NSMutableArray* arr = [NSMutableArray arrayWithArray:self.groups];
    [arr addObject:g];
    self.groups = [NSArray arrayWithArray:arr];
}

- (void)saveSortOrder {
    NSMutableArray* sortedGroupIds = [NSMutableArray array];
    for (Group* g in self.groups) {
        [sortedGroupIds addObject:$str(@"%d", g.id)];
    }
    NSDictionary* dict = $dict(sortedGroupIds, @"sorted_group_ids");
    [dict yamlWriteDocumentsFile:@"groups_order.yaml"];
}

- (void)load {    
    // Load them all    
    NSMutableArray* arr = [NSMutableArray array];
    NSArray* files = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:[$ documentPath] error:nil];
    for (NSString* file in files) {
        if ([file hasPrefix:@"group_"] && [file hasSuffix:@".yaml"]) {
            NSDictionary *dict = [file readDocumentsFileAsYaml];
            [arr addObject:[Group groupFromYamlDict:dict]];
        }
    }
        
    // If empty and this is the first use, open up initialgroups, and save them all out
    if (!arr.count) {
        if (![[NSUserDefaults standardUserDefaults] boolForKey:@"readInitialGroups"]) {
            [[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"readInitialGroups"];
            [[NSUserDefaults standardUserDefaults] synchronize];
            
            NSDictionary* yaml = [@"InitialGroups.yaml" readBundleFileAsYaml];
            for (NSDictionary* dict in [yaml objectForKey:@"groups"]) {
                Group* g = [Group groupFromYamlDict:dict];
                [g save];
                [arr addObject:g];
            }
            self.groups=arr;
            [self saveSortOrder];
        }
    }
        
    // Sort them
    NSDictionary* yamlSort = [@"groups_order.yaml" readDocumentsFileAsYaml];
    NSMutableArray* sorted = [NSMutableArray array];
    for (NSString* id in [yamlSort $for:@"sorted_group_ids"]) {
        // Find the matching group for this id
        for (Group* g in arr) {
            if (g.id == id.intValue) {
                [sorted addObject:g];
                [arr removeObject:g];
                break;
            }
        }
    }
    // Now add the ones that the sort order didn't specify
    [sorted addObjectsFromArray:arr];
    
    self.groups = [NSArray arrayWithArray:sorted];
}

// Make a default group in case the user deletes all the groups!
- (void)makeAtLeastOneGroup {
    if (!self.groups.count) {
        Group* g = [[Group alloc] init];
        g.name = @"Passwords";
        g.icon = @"237-key";
        g.hue = 0;
        g.id = arc4random()%1000000;        
        [g save];
        [self addGroup:g];
    }   
}

// Finds the group, or the first one if no match found (eg orphaned items)
- (Group*)groupById:(int)id {
    for (Group* g in groups) {
        if (g.id == id) return g;
    }
    return nil;
}

@end
