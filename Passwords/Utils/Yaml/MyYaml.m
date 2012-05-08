//
//  MyYaml.m
//  RetroQuest
//
//  Created by Chris Hulbert on 24/01/12.
//  Copyright (c) 2012 Splinter Software. All rights reserved.
//

#import "MyYaml.h"
#import "YAMLKit.h"
#import "ConciseKit.h"

@implementation NSString(NSString_Yaml)

- (NSDictionary*)readBundleFileAsYaml {
    NSString* path = [[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:self];
    return [YAMLKit loadFromFile:path];
}

- (NSDictionary*)readDocumentsFileAsYaml {
    NSString* path = [[$ documentPath] stringByAppendingPathComponent:self];
    return [YAMLKit loadFromFile:path];
}

- (NSDictionary*)readPathAsYaml {
    return [YAMLKit loadFromFile:self];
}

@end

@implementation NSDictionary(NSDictionary_Yaml)

- (NSString*)yamlEncode {
    return [YAMLKit dumpObject:self];
}

- (void)yamlWriteDocumentsFile:(NSString*)filename {
    NSString* path = [[$ documentPath] stringByAppendingPathComponent:filename];
    [YAMLKit dumpObject:self toFile:path];
}

@end
