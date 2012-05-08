//
//  YKEmitter.m
//  YAMLKit
//
//  Created by Patrick Thomson on 12/29/08.
//

#import "YKEmitter.h"

@interface YKEmitter (YKEmitterPrivateMEthods)

- (int)_writeItem:(id)item toDocument:(yaml_document_t *)document;

@end

@implementation YKEmitter

@synthesize usesExplicitDelimiters, encoding;

- (id)init
{
    if((self = [super init])) {
        memset(&emitter, 0, sizeof(emitter));
        yaml_emitter_initialize(&emitter);
        
        buffer = [NSMutableData data];
        // Coincidentally, the order of arguments to CFDataAppendBytes are just right
        // such that if I pass the buffer as the data parameter, I can just use 
        // a pointer to CFDataAppendBytes to tell the emitter to write to the NSMutableData.
        yaml_emitter_set_output(&emitter, (yaml_write_handler_t*)CFDataAppendBytes, buffer);
        [self setUsesExplicitDelimiters:NO];
    }
	return self;
}

- (void)emitItem:(id)item
{
    // Create and initialize a document to hold this.
    yaml_document_t document;
    memset(&document, 0, sizeof(document));
    // The double usage of !usesExplicitDelimiters corresponds to explicitly
	// delimiting the start and end of various documents.
    yaml_document_initialize(&document, NULL, NULL, NULL, !usesExplicitDelimiters, !usesExplicitDelimiters);
    // TODO: Make this into a proper private method.
    [self _writeItem:item toDocument:&document];
    yaml_emitter_dump(&emitter, &document);
    yaml_document_delete(&document);
}

- (int)_writeItem:(id)item toDocument:(yaml_document_t *)doc
{
	int nodeID = 0;
	// #keyEnumerator covers NSMapTable/NSHashTable/NSDictionary 
	if([item respondsToSelector:@selector(keyEnumerator)]) {
		// Add a mapping node.
		nodeID = yaml_document_add_mapping(doc, (yaml_char_t *)YAML_DEFAULT_MAPPING_TAG, YAML_ANY_MAPPING_STYLE);
		for(id key in item) {
			int keyID = [self _writeItem:key toDocument:doc];
			int valueID = [self _writeItem:[item objectForKey:key] toDocument:doc];
			yaml_document_append_mapping_pair(doc, nodeID, keyID, valueID);
		}
	// #objectEnumerator covers NSSet/NSArray.
	} else if([item respondsToSelector:@selector(objectEnumerator)]) {
		// emit beginning sequence
		nodeID = yaml_document_add_sequence(doc, (yaml_char_t *)YAML_DEFAULT_SEQUENCE_TAG, YAML_ANY_SEQUENCE_STYLE);
		for(id subitem in item) {
			int newItem = [self _writeItem:subitem toDocument:doc];
			yaml_document_append_sequence_item(doc, nodeID, newItem);
		}
	// Everything else is a scalar.
	} else {
		// TODO: Add optional support for tagging emitted items.
		// TODO: Wrap long lines.
		nodeID = yaml_document_add_scalar(doc, (yaml_char_t *)YAML_DEFAULT_SCALAR_TAG, (yaml_char_t*)[[item description] UTF8String], [[item description] length], YAML_ANY_SCALAR_STYLE);
	}
	return nodeID;
}

- (NSString *)emittedString
{
    return [[[NSString alloc] initWithData:buffer encoding:NSUTF8StringEncoding] autorelease];
}

- (NSData *)emittedData
{
	return [NSData dataWithData:buffer];
}

- (void)setEncoding:(NSStringEncoding)newEnc
{
	encoding = newEnc;
	yaml_encoding_t converted = YAML_ANY_ENCODING;
	switch(encoding) {
		case NSUTF8StringEncoding:
			converted = YAML_UTF8_ENCODING;
			break;
		case NSUTF16LittleEndianStringEncoding:
			converted = YAML_UTF16LE_ENCODING;
			break;
		case NSUTF16BigEndianStringEncoding:
			converted = YAML_UTF16BE_ENCODING;
			break;
		default:
			NSLog(@"Unsupported encoding passed to YKEmitter#setEncoding:.");
			break;
	}
	yaml_emitter_set_encoding(&emitter, converted);
}

@end
