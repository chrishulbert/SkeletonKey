//
//  EnterPassword.m
//  Passwords
//
//  Created by Chris Hulbert on 23/02/12.
//  Copyright (c) 2012 Splinter Software. All rights reserved.
//

#import "EnterPassword.h"
#import "Password.h"

//#define launchShots

@implementation EnterPassword

@synthesize pass, hideKeyboard;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
        self.title = @"Skeleton Key";
    }
    return self;
}

- (void)tapDone {
    if (!self.pass.text.length) {
        [[[UIAlertView alloc] initWithTitle:nil message:@"You'll need to enter a password to unlock this app" delegate:nil cancelButtonTitle:@"Ok" otherButtonTitles:nil] show];
        return;
    }
    BOOL validatedOk = [[Password i] validatePassword:self.pass.text];
    if (validatedOk) {
        [self dismissModalViewControllerAnimated:YES];
    } else {
        self.pass.text = @"";
        [[[UIAlertView alloc] initWithTitle:nil message:@"Incorrect password" delegate:nil cancelButtonTitle:@"Ok" otherButtonTitles:nil] show];
    }
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    [self tapDone];
    return NO;
}

#pragma mark - View lifecycle

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor colorWithPatternImage:[UIImage imageNamed:@"wood"]];
#ifdef launchShots
    self.pass.placeholder=nil;
#endif
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
#ifndef launchShots
    if (!self.hideKeyboard) {
        [self.pass becomeFirstResponder];
    }
#endif
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

@end
