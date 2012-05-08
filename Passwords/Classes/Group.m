//
//  Group.m
//  Passwords
//
//  Created by Chris Hulbert on 14/02/12.
//  Copyright (c) 2012 Splinter Software. All rights reserved.
//

#import "Group.h"
#import "ConciseKit.h"
#import "MyYaml.h"

@implementation Group

@synthesize name, icon, hue, id;

+ (Group*)groupFromYamlDict:(NSDictionary*)d {
    //- name: Web
    //icon: 243-globe
    //id: 951895
    Group* g = [[Group alloc] init];
    g.name = [d $for:@"name"];
    g.icon = [d $for:@"icon"];
    g.id = [[d $for:@"id"] intValue];
    g.hue = [[d $for:@"hue"] intValue];
    return g;
}

- (NSString*)description {
    return $str(@"Group %d: %@", id, name);
}

- (UIColor*)colour {
    return [UIColor colorWithHue:self.hue/360.0f saturation:1 brightness:.5 alpha:1];
}

- (void)save {
    NSDictionary* yaml = $dict(self.name, @"name", self.icon, @"icon", $int(self.hue), @"hue", $int(self.id), @"id");
    NSString* yamlString = [yaml yamlEncode];
    NSString* path = [$.documentPath stringByAppendingPathComponent:$str(@"group_%d.yaml", self.id)];
    NSError* err=nil;
    [yamlString writeToFile:path atomically:NO encoding:NSUTF8StringEncoding error:&err];
    if (err) {
        [[[UIAlertView alloc] initWithTitle:@"Could not save group" message:err.localizedDescription delegate:nil cancelButtonTitle:@"Ok" otherButtonTitles:nil] show];
    }
}

- (void)deleteFile {
    NSString* path = [$.documentPath stringByAppendingPathComponent:$str(@"group_%d.yaml", self.id)];
    [[NSFileManager defaultManager] removeItemAtPath:path error:nil];
}

@end
