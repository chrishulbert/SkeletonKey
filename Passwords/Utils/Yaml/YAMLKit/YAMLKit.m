//
//  YAMLKit.m
//  YAMLKit
//
//  Created by Patrick Thomson on 12/30/08.
//  Copyright 2008 Patrick Thomson. All rights reserved.
//

#import "YAMLKit.h"

@implementation YAMLKit

+ (id)loadFromString:(NSString *)str
{
    YKParser *p = [[[YKParser alloc] init] autorelease];
	[p readString:str];
    NSArray *result = [p parse];
    // If parse returns a one-element array, extract it.
    if([result count] == 1) {
        return [result objectAtIndex:0];
    }
    return result;
}

+ (id)loadFromFile:(NSString *)path
{
	NSString *contents = [NSString stringWithContentsOfFile:path 
												   encoding:NSUTF8StringEncoding 
													  error:NULL];
	if(contents == nil) return nil; // if there was an error reading from the file
	return [self loadFromString:contents];
}

+ (id)loadFromURL:(NSURL *)url
{
	NSString *contents = [NSString stringWithContentsOfURL:url 
												  encoding:NSUTF8StringEncoding 
													 error:NULL];
	if(contents == nil) return nil; // if there was an error reading from the URL
	return [self loadFromString:contents];
}

+ (NSString *)dumpObject:(id)object
{
    YKEmitter *e = [[[YKEmitter alloc] init] autorelease];
    [e emitItem:object];
    return [e emittedString];
}

+ (BOOL)dumpObject:(id)object toFile:(NSString *)path
{
	YKEmitter *e = [[[YKEmitter alloc] init] autorelease];
	[e emitItem:object];
	return [[e emittedString] writeToFile:path
							   atomically:YES
								 encoding:NSUTF8StringEncoding
									error:NULL];
}

+ (BOOL)dumpObject:(id)object toURL:(NSURL *)path
{
	YKEmitter *e = [[[YKEmitter alloc] init] autorelease];
	[e emitItem:object];
	return [[e emittedString] writeToURL:path
							  atomically:YES
								encoding:NSUTF8StringEncoding
								   error:NULL];
}



@end
