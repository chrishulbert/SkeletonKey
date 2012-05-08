//
//  SetPassword.m
//  Passwords
//
//  Created by Chris Hulbert on 17/02/12.
//  Copyright (c) 2012 Splinter Software. All rights reserved.
//

#import "SetPassword.h"
#import "Password.h"
#import "ConciseKit.h"
#import "DropboxSDK.h"

#define setPasswordAlertTag 1
#define pairFirstAlertTag   2

@implementation SetPassword

@synthesize password1, password2;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
        self.title = @"Set Password";
        self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:(UIBarButtonSystemItemSave) target:self action:@selector(tapSave)];
        
        self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:(UIBarButtonSystemItemCancel) target:self action:@selector(tapCancel)];
    }
    return self;
}

- (void)tapCancel {
    [self dismissModalViewControllerAnimated:YES];
}

- (void)showHelpAlert {
    [[[UIAlertView alloc] initWithTitle:@"Master Password" message:@"Before you can start storing any data, you'll need to set a master password. This password is used to encrypt all your other data, so it's important!" delegate:nil cancelButtonTitle:@"Ok" otherButtonTitles:nil] show];
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    if (alertView.tag == setPasswordAlertTag) {
        if (buttonIndex==alertView.firstOtherButtonIndex) {
            [[Password i] setPassword:self.password1.text];
            [self dismissModalViewControllerAnimated:YES];
        }
    }
    if (alertView.tag == pairFirstAlertTag) {
        if (buttonIndex == alertView.firstOtherButtonIndex) {
            [self dismissModalViewControllerAnimated:YES];
            [[DBSession sharedSession] link];
        }
        if (buttonIndex == alertView.cancelButtonIndex) {
            [self showHelpAlert];
        }
    }
}

- (void)tapSave {
    NSString* err=nil;
    if (self.password1.text.length < Password.minLength) {
        err = $str(@"Password must have at least %d characters", [Password minLength]);
    }
    if (!$eql(self.password1.text, self.password2.text)) {
        err = @"You must enter the password twice";
    }
    if (err) {
        [[[UIAlertView alloc] initWithTitle:@"Error" message:err delegate:nil cancelButtonTitle:@"Ok" otherButtonTitles:nil] show];
        return;
    }
    
    UIAlertView* av = [[UIAlertView alloc] initWithTitle:nil message:@"Please ensure that you've written down this master password and stored it in a safe place. If you lose it, there is NO WAY of decrypting your data in this app." delegate:self cancelButtonTitle:@"Cancel" otherButtonTitles:@"Ok", nil];
    av.tag = setPasswordAlertTag;
    [av show];
}

#pragma mark - View lifecycle

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    [self.password1 becomeFirstResponder];
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:YES];
        
    if ([[DBSession sharedSession] isLinked]) {
        [self showHelpAlert];
    } else { // Not linked
        // If they're not linked, say that they should link first, especially if they already have an keychain on dropbox. Have a button to jump to linking and close this
        UIAlertView* av = [[UIAlertView alloc] initWithTitle:@"Dropbox" message:@"I highly recommend that you link to Dropbox first, before setting a master password, if you intend using the Dropbox syncing features" delegate:self cancelButtonTitle:@"No thanks" otherButtonTitles:@"Pair with Dropbox", nil];
        av.tag = pairFirstAlertTag;
        [av show];
    }
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    if (textField==self.password1) [self.password2 becomeFirstResponder];
    if (textField==self.password2) {
        [self tapSave];
    }
    return NO;
}


@end
