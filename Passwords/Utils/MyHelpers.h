//
//  MyHelpers.h
//  Reminders
//
//  Created by Chris Hulbert on 9/02/12.
//  Copyright (c) 2012 Splinter Software. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface MyHelpers : NSObject

+ (UILabel*)makeTitleView:(NSString*)title;
+ (void)setNoRowsMessage:(UITableView*)table show:(BOOL)show message:(NSString*)message;

@end
