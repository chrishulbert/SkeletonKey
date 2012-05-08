//
//  Help.m
//  Passwords
//
//  Created by Chris Hulbert on 21/03/12.
//  Copyright (c) 2012 Splinter Software. All rights reserved.
//

#import "Help.h"

@interface Help ()

@end

@implementation Help

@synthesize web;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.title = @"Help";
    
    NSString *path = [[NSBundle mainBundle] pathForResource:@"help" ofType:@"html"];
    NSURL *url = [NSURL fileURLWithPath:path];
    NSURLRequest *request = [NSURLRequest requestWithURL:url];
    [self.web loadRequest:request];
//    NSURL *url = [NSURL URLWithString:@"http://apps.splinter.com.au"];
//    NSURLRequest *requestObj = [NSURLRequest requestWithURL:url];
//    [self.web loadRequest:requestObj];
}

- (BOOL)webView:(UIWebView *)inWeb shouldStartLoadWithRequest:(NSURLRequest *)inRequest navigationType:(UIWebViewNavigationType)inType {
    
    if (inType == UIWebViewNavigationTypeLinkClicked ) {
        [[UIApplication sharedApplication] openURL:[inRequest URL]];
        return NO;
    }
    
    return YES;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

@end
