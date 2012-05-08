//
//  Item.m
//  Passwords
//
//  Created by Chris Hulbert on 23/02/12.
//  Copyright (c) 2012 Splinter Software. All rights reserved.
//

#import "Item.h"
#import "ConciseKit.h"
#import "Password.h"
#import "MyYaml.h"

@implementation Item

@synthesize name, id, groupId, fields, notes;

- (NSString*)filePath {
    return [[$ documentPath] stringByAppendingPathComponent:$str(@"item_%d.yaml", self.id)];
}

// Converts nsnulls or nils to zero length strings
- (NSString*)nilToStr:(NSString*)str {
    if (!str) return @"";
    if ((id)str == [NSNull null]) return @"";
    if (![str isKindOfClass:[NSString class]]) return str.description;
    return str;
}

- (void)save {
    NSMutableArray* yamlFields = [NSMutableArray array];
    for (NSArray* arr in self.fields) {
        NSString* fieldName = [arr objectAtIndex:0];
        NSString* fieldValue = [arr objectAtIndex:1];
        [yamlFields addObject:$dict(fieldName, @"name",
                                    [[Password i] encrypt:fieldValue], @"value")];
    }
    NSDictionary* yaml = $dict(self.name, @"name",
                               $int(self.id), @"id",
                               $int(self.groupId), @"group_id",
                               [self nilToStr:[[Password i] encrypt:self.notes]], @"notes",
                               yamlFields, @"fields");
    NSString* yamlString = [yaml yamlEncode];
    NSError* err=nil;
    [yamlString writeToFile:[self filePath] atomically:NO encoding:NSUTF8StringEncoding error:&err];
    if (err) {
        [[[UIAlertView alloc] initWithTitle:@"Could not save item" message:err.localizedDescription delegate:nil cancelButtonTitle:@"Ok" otherButtonTitles:nil] show];
    }
}

- (void)deleteFile {
    [[NSFileManager defaultManager] removeItemAtPath:self.filePath error:nil];
}

+ (Item*)loadItemById:(int)id {
    // Does it exist?
    Item* i = [[Item alloc] init];
    i.id = id;
    if (![[NSFileManager defaultManager] fileExistsAtPath:i.filePath]) return nil;
    
    // Load it
    NSDictionary* yaml = [i.filePath readPathAsYaml];
    i.name = [yaml $for:@"name"];
    if (!i.name.length) return nil;
    if (id != [[yaml $for:@"id"] intValue]) return nil;
    i.groupId = [[yaml $for:@"group_id"] intValue];
    i.notes = [[Password i] decrypt:[yaml $for:@"notes"]];

    // Load fields
    NSMutableArray* arr = [NSMutableArray array];
    for (NSDictionary* d in [yaml $for:@"fields"]) {
        NSString* fieldName = [d $for:@"name"];
        NSString* cryptVal = [d $for:@"value"];
        if (fieldName.length) {
            if (cryptVal.length) {
                [arr addObject:$arr(fieldName, [[Password i] decrypt:cryptVal])];
            } else {
                [arr addObject:$arr(fieldName, @"")];
            }
        }
    }
    i.fields = [NSArray arrayWithArray:arr];
    
    return i;
}


@end
