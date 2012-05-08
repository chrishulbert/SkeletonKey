//
//  YKEncoder.h
//  YAMLKit
//
//  Created by Patrick Thomson on 12/29/08.
//

#import <Foundation/Foundation.h>
#import "yaml.h"

@interface YKEmitter : NSObject {
    yaml_emitter_t emitter;
    NSMutableData *buffer;
	BOOL usesExplicitDelimiters;
	NSStringEncoding encoding;
}

- (void)emitItem:(id)item;
- (NSString *)emittedString;
- (NSData *)emittedData;

@property(assign) BOOL usesExplicitDelimiters;
@property(readonly,assign) NSStringEncoding encoding;


@end
