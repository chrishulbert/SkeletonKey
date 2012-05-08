//
//  MyKeyChain.h
//  ThreeUsage
//
//  Created by Chris on 10/07/11.
//  Copyright 2011 Splinter Software. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface MyKeyChain : NSObject {
    
}

+ (void)setValue:(NSString*)value forKey:(NSString*)key;
+ (NSString*)get:(NSString*)key;

@end
