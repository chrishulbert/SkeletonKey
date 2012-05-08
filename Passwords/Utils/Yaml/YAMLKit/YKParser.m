//
//  YKParser.m
//  YAMLKit
//
//  Created by Patrick Thomson on 12/29/08.
//

#import "YKParser.h"
#import "YKConstants.h"


static BOOL _isBooleanTrue(NSString *aString);
static BOOL _isBooleanFalse(NSString *aString);

@interface YKParser (YKParserPrivateMethods)

- (id)_interpretObjectFromEvent:(yaml_event_t)event;
- (NSError *)_constructErrorFromParser:(yaml_parser_t *)p;

@end

@implementation YKParser

@synthesize readyToParse;

- (void)reset
{
    if(fileInput) {
        fclose(fileInput);
    }
	yaml_parser_delete(&parser);
    memset(&parser, 0, sizeof(parser));
}

- (BOOL)readFile:(NSString *)path
{
    [self reset];
    fileInput = fopen([path fileSystemRepresentation], "r");
    readyToParse = ((fileInput != NULL) && (yaml_parser_initialize(&parser)));
    if(readyToParse) 
		yaml_parser_set_input_file(&parser, fileInput);
	return readyToParse;
}

- (BOOL)readString:(NSString *)str
{
    [self reset];
    stringInput = [str UTF8String];
    readyToParse = yaml_parser_initialize(&parser);
    if(readyToParse) 
		yaml_parser_set_input_string(&parser, (const unsigned char *)stringInput, [str length]);
    return readyToParse;
}

- (NSArray *)parse
{
	return [self parseWithError:NULL];
}

- (NSArray *)parseWithError:(NSError **)e
{
    yaml_event_t event;
    int done = 0;
    id obj, temp;
    NSMutableArray *stack = [NSMutableArray array];
	if(!readyToParse) {
		if(![[stack lastObject] isKindOfClass:[NSMutableDictionary class]]){
			if(e != NULL) {
				*e = [self _constructErrorFromParser:NULL];
				return nil;
			}
		}		
	}
    
    while(!done) {
        if(!yaml_parser_parse(&parser, &event)) {
			if(e != NULL) {
				*e = [self _constructErrorFromParser:&parser];
			}
            return nil;
		}
        done = (event.type == YAML_STREAM_END_EVENT);
        switch(event.type) {
            case YAML_SCALAR_EVENT:
				obj = [self _interpretObjectFromEvent:event];
                temp = [stack lastObject];
                
                if([temp isKindOfClass:[NSArray class]]) {
                    [temp addObject:obj];
                } else if([temp isKindOfClass:[NSDictionary class]]) {
                    [stack addObject:obj];
                } else if([temp isKindOfClass:[NSString class]] || [temp isKindOfClass:[NSValue class]])  {
                    [temp retain];
                    [stack removeLastObject];
                    if(![[stack lastObject] isKindOfClass:[NSMutableDictionary class]]){
						if(e != NULL) {
							*e = [self _constructErrorFromParser:NULL];
							return nil;
						}
					}
					[[stack lastObject] setObject:obj forKey:temp];
                }
                
                break;
            case YAML_SEQUENCE_START_EVENT:
                [stack addObject:[NSMutableArray array]];
                break;
            case YAML_MAPPING_START_EVENT:
                [stack addObject:[NSMutableDictionary dictionary]];
                break;
            case YAML_SEQUENCE_END_EVENT:
            case YAML_MAPPING_END_EVENT:
				// TODO: Check for retain count errors.
                temp = [stack lastObject];
                [stack removeLastObject];
		                
                id last = [stack lastObject];
				if(last == nil) {
					[stack addObject:temp];
					break;
				} else if([last isKindOfClass:[NSArray class]]) {
                    [last addObject:temp];
                } else if ([last isKindOfClass:[NSDictionary class]]) {
                    [stack addObject:temp];
                } else if ([last isKindOfClass:[NSString class]] || [last isKindOfClass:[NSNumber class]]) {
                    obj = [[stack lastObject] retain];
                    [stack removeLastObject];
                    if(![[stack lastObject] isKindOfClass:[NSMutableDictionary class]]){
						if(e != NULL) {
							*e = [self _constructErrorFromParser:NULL];
							return nil;
						}
					}					
                    [[stack lastObject] setObject:temp forKey:obj];
                }
                break;
            case YAML_NO_EVENT:
                break;
            default:
                break;
        }
        yaml_event_delete(&event);
    }
    return stack;
}

// TODO: oof, add tag support.

- (id)_interpretObjectFromEvent:(yaml_event_t)event
{
	NSString *stringValue = [NSString stringWithUTF8String:(const char *)event.data.scalar.value];
	id obj = stringValue;
	
	if(event.data.scalar.style == YAML_PLAIN_SCALAR_STYLE) {
		NSScanner *scanner = [NSScanner scannerWithString:obj];
		
		// Integers are automatically casted unless given a !!str tag. I think.
		if([scanner scanDouble:NULL] && [scanner scanLocation] == [stringValue length]) {
			obj = [NSNumber numberWithDouble:[obj doubleValue]];
		} else if([scanner scanInt:NULL] && [scanner scanLocation] == [stringValue length]) {
			obj = [NSNumber numberWithInt:[obj intValue]];
		// FIXME: Boolean parsing here is not in accordance with the YAML standards.
		} else if(_isBooleanTrue((NSString *)obj))     {
			obj = [NSNumber numberWithBool:YES];
		} else if(_isBooleanFalse((NSString *)obj))    {
			obj = [NSNumber numberWithBool:NO];
		} else if([obj isEqualToString:@"~"]) {
			obj = [NSNull null];
		}
		// TODO: add date parsing.
	}
	return obj;
}

- (NSError *)_constructErrorFromParser:(yaml_parser_t *)p
{
	int code = 0;
	NSMutableDictionary *data = [NSMutableDictionary dictionary];
	
	if(p != NULL) {
		// actual parser error
		code = p->error;
		// get the string encoding.
		NSStringEncoding enc = 0;
		switch (p->encoding) {
			case YAML_UTF8_ENCODING:
				enc = NSUTF8StringEncoding;
				break;
			case YAML_UTF16LE_ENCODING:
				enc = NSUTF16LittleEndianStringEncoding;
				break;
			case YAML_UTF16BE_ENCODING:
				enc = NSUTF16BigEndianStringEncoding;
				break;
			default: break;
		}
		[data setObject:[NSNumber numberWithInt:enc] forKey:NSStringEncodingErrorKey];
		
		[data setObject:[NSString stringWithUTF8String:p->problem] forKey:YKProblemDescriptionKey];
		[data setObject:[NSNumber numberWithInt:p->problem_offset] forKey:YKProblemOffsetKey];
		[data setObject:[NSNumber numberWithInt:p->problem_value] forKey:YKProblemValueKey];
		[data setObject:[NSNumber numberWithInt:p->problem_mark.line] forKey:YKProblemLineKey];
		[data setObject:[NSNumber numberWithInt:p->problem_mark.index] forKey:YKProblemIndexKey];
		[data setObject:[NSNumber numberWithInt:p->problem_mark.column] forKey:YKProblemColumnKey];
		
		[data setObject:[NSString stringWithUTF8String:p->context] forKey:YKErrorContextDescriptionKey];
		[data setObject:[NSNumber numberWithInt:p->context_mark.line] forKey:YKErrorContextLineKey];
		[data setObject:[NSNumber numberWithInt:p->context_mark.column] forKey:YKErrorContextColumnKey];
		[data setObject:[NSNumber numberWithInt:p->context_mark.index] forKey:YKErrorContextIndexKey];
		
	} else if(readyToParse) {
		[data setObject:NSLocalizedString(@"Internal assertion failed, possibly due to specially malformed input.", @"") forKey:NSLocalizedDescriptionKey];
	} else {
		[data setObject:NSLocalizedString(@"YAML parser was not ready to parse.", @"") forKey:NSLocalizedFailureReasonErrorKey];
		[data setObject:NSLocalizedString(@"Did you remember to call readFile: or readString:?", @"") forKey:NSLocalizedDescriptionKey];
	}
	
	return [[NSError alloc] initWithDomain:YKErrorDomain code:code userInfo:data];
}

- (void)finalize
{
	yaml_parser_delete(&parser);
	if(fileInput != NULL) fclose(fileInput);
	[super finalize];
}

- (void)dealloc
{
	yaml_parser_delete(&parser);
	if(fileInput != NULL) fclose(fileInput);
    [super dealloc];
}

@end

static BOOL _isBooleanFalse(NSString *aString)
{
	BOOL isFalse = NO;
	const char *cstr = [aString UTF8String];
	char *falseValues[] = {
		"false", "False", "FALSE",
		"n", "N", "NO", "No", "no",
		"off", "Off", "OFF"
	};
	size_t length = sizeof(falseValues) / sizeof(*falseValues);
	int index;
	for(index = 0; index < length && !isFalse; index++) {
		isFalse = strcmp(cstr, falseValues[index]) == 0;
	}
	return isFalse;
}

static BOOL _isBooleanTrue(NSString *aString)
{
	BOOL isTrue = NO;
	const char *cstr = [aString UTF8String];
	char *trueValues[] = {
		"true", "TRUE", "True",
		"y", "Y", "Yes", "yes", "YES",
		"on", "On", "ON"
	};
	size_t length = sizeof(trueValues) / sizeof(*trueValues);
	int index;
	for(index = 0; index < length && !isTrue; index++) {
		isTrue = strcmp(cstr, trueValues[index]) == 0;
	}
	return isTrue;
}
