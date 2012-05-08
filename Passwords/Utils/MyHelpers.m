//
//  MyHelpers.m
//  Reminders
//
//  Created by Chris Hulbert on 9/02/12.
//  Copyright (c) 2012 Splinter Software. All rights reserved.
//

#import "MyHelpers.h"
#import <QuartzCore/QuartzCore.h>

@implementation MyHelpers

+ (UILabel*)makeTitleView:(NSString*)title {
    UILabel* lbl = [[UILabel alloc] init];
    lbl.text = title;
    lbl.font = [UIFont fontWithName:@"HelveticaNeue-Light" size:24];
    CGSize idealSize = [lbl.text sizeWithFont:lbl.font];
    lbl.frame = CGRectMake(0, 0, idealSize.width, 44);
    lbl.textAlignment = UITextAlignmentCenter;
    lbl.backgroundColor = [UIColor clearColor];
    lbl.textColor = [UIColor whiteColor];
    lbl.shadowColor = [UIColor blackColor];
    return lbl;
}

+ (void)setNoRowsMessage:(UITableView*)table show:(BOOL)show message:(NSString*)message {
    const int tag = 1001;
    if (show) {
        if (![table viewWithTag:tag]) {
            UILabel* lbl = [[UILabel alloc] init];
            lbl.text = message;
            lbl.numberOfLines = 0;
            lbl.font = [UIFont italicSystemFontOfSize:16];
            lbl.frame = CGRectMake(table.frame.size.width/2-100, table.frame.size.height/2-56, 200, 112);
            lbl.textAlignment = UITextAlignmentCenter;
            lbl.backgroundColor = [UIColor colorWithWhite:0 alpha:0.5];
            lbl.textColor = [UIColor whiteColor];
            lbl.tag = tag;
            lbl.layer.cornerRadius = 10;
            [table addSubview:lbl];
        }
    } else {
        [[table viewWithTag:tag] removeFromSuperview];
    }
}

@end
