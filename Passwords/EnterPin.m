//
//  EnterPin.m
//  Passwords
//
//  Created by Chris Hulbert on 27/02/12.
//  Copyright (c) 2012 Splinter Software. All rights reserved.
//

#import "EnterPin.h"
#import "Password.h"
#import "EnterPassword.h"

@implementation EnterPin

@synthesize pin, hideKeyboard;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        self.title = @"Skeleton Key";
        self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:(UIBarButtonSystemItemStop) target:self action:@selector(tapForgetPin)];
    }
    return self;
}

#pragma mark - View lifecycle

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor colorWithPatternImage:[UIImage imageNamed:@"wood"]];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    if (!self.hideKeyboard) {
        [self.pin becomeFirstResponder];
    }
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

-(void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex {
    if (buttonIndex == alertView.firstOtherButtonIndex) {
        // Delete the PIN
        [Password pinRemove];
        // Open the password entry
        EnterPassword* p = [[EnterPassword alloc] initWithNibName:@"EnterPassword" bundle:nil];
        [self.navigationController setViewControllers:[NSArray arrayWithObject:p] animated:YES];
    }
}

- (void)tapForgetPin {
    [[[UIAlertView alloc] initWithTitle:@"Delete PIN" message:@"Would you like to delete the PIN, and revert to using the master password for access?" delegate:self cancelButtonTitle:@"Cancel" otherButtonTitles:@"Delete PIN", nil] show];
}

- (void)clearPin {
    self.pin.text = @"";
}

- (void)done:(NSString*)enteredPin {
    BOOL validatedOk = [[Password i] validatePin:enteredPin];
    if (validatedOk) {
        [self dismissModalViewControllerAnimated:YES];
    } else {
        [self performSelector:@selector(clearPin) withObject:nil afterDelay:0.001]; // Done this way so the callback chain gets to exit and apply the 4th char
        [[[UIAlertView alloc] initWithTitle:nil message:@"Incorrect PIN. If you've forgotten your PIN, you can revert to using the master password by pressing the top left button." delegate:nil cancelButtonTitle:@"Ok" otherButtonTitles:nil] show];
    }
}

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string {
    NSString* new = [textField.text stringByReplacingCharactersInRange:range withString:string];
    if (new.length==4) {
        [self done:new];
    }    
    return YES;
}


@end
