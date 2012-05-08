//
//  SetPin.m
//  Passwords
//
//  Created by Chris Hulbert on 27/02/12.
//  Copyright (c) 2012 Splinter Software. All rights reserved.
//

#import "SetPin.h"
#import "Password.h"
#import "ConciseKit.h"

@implementation SetPin

@synthesize pin;

#pragma mark - View lifecycle

- (void)viewDidLoad {
    self.title = @"Set PIN";
    [super viewDidLoad];
    [self.pin becomeFirstResponder];
}

- (void)viewDidUnload {
    [super viewDidUnload];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string {
    NSString* new = [textField.text stringByReplacingCharactersInRange:range withString:string];
    if (new.length==4) {
        [[Password i] pinSetNew:new];
        [[[UIAlertView alloc] initWithTitle:@"PIN"
                                    message:$str(@"Your PIN has been set: %@.\n"
                                                 "However, you still must never lose your master password, as you will still require it.", new)
                                   delegate:nil cancelButtonTitle:@"Ok" otherButtonTitles:nil] show];
        [self.navigationController popViewControllerAnimated:YES];
    }    
    return YES;
}

@end
