//
//  Yaml.h
//  RetroQuest
//
//  Created by Chris Hulbert on 24/01/12.
//  Copyright (c) 2012 Splinter Software. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSString(NSString_Yaml)

- (NSDictionary*)readBundleFileAsYaml;
- (NSDictionary*)readDocumentsFileAsYaml;
- (NSDictionary*)readPathAsYaml;

@end

@interface NSDictionary(NSDictionary_Yaml)

- (NSString*)yamlEncode;
- (void)yamlWriteDocumentsFile:(NSString*)filename;

@end
