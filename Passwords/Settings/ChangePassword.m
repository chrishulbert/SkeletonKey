//
//  ChangePassword.m
//  Passwords
//
//  Created by Chris Hulbert on 26/02/12.
//  Copyright (c) 2012 Splinter Software. All rights reserved.
//

#import "ChangePassword.h"
#import "Password.h"
#import "ConciseKit.h"
#import "CHBgDropboxSync.h"
#import "DropboxClearer.h"

@implementation ChangePassword

@synthesize old,pass1,pass2;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
        self.title = @"Change Password";
        self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:(UIBarButtonSystemItemDone) target:self action:@selector(tapDone)];
    }
    return self;
}

- (void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex {
    if (buttonIndex==alertView.firstOtherButtonIndex) {
        // This is the only part of the app where the password is changed
        // The strategy is: stop syncing, clear the last sync data, clear dropbox, CHANGE PASSWORD, restart sync (ie push to db)
        [CHBgDropboxSync forceStopIfRunning]; // Stop syncing
        UIAlertView* clearing = [[UIAlertView alloc] initWithTitle:nil message:@"Clearing Dropbox" delegate:nil cancelButtonTitle:nil otherButtonTitles:nil]; // Show a 'clearing' display
        [clearing show];
        [CHBgDropboxSync clearLastSyncData]; // Clear last sync data *first* so if anything borks, nothing will be deleted next sync
        [DropboxClearer doClear:^(BOOL success) { // Erase everything on dropbox
            [clearing dismissWithClickedButtonIndex:0 animated:YES];
            if (success) {
                // Actually change the password!
                NSString* err = [[Password i] changePasswordFrom:self.old.text to:self.pass1.text];
                if (err) {
                    [[[UIAlertView alloc] initWithTitle:@"Error" message:err delegate:nil cancelButtonTitle:@"Ok" otherButtonTitles:nil] show];
                } else {
                    [[[UIAlertView alloc] initWithTitle:@"Password changed" message:@"Your master password has now been changed.\n"
                      "Once this device finishes syncing, you should then get your other devices that have this app installed to sync, so that they pick up all the data that has been re-encrypted under the new password.\n"
                      "Please ensure that you've written the master password down and stored it in a safe place. If you lose it, there is NO WAY of decrypting your data in this app, besides restoring an old backup." delegate:nil cancelButtonTitle:@"Ok" otherButtonTitles:nil] show];
                    [CHBgDropboxSync start]; // Start sync again
                    [self.navigationController popViewControllerAnimated:YES]; // Close me
                }
            } else {
                [[[UIAlertView alloc] initWithTitle:@"Error" message:@"Couldn't clear dropbox, password change cancelled." delegate:nil cancelButtonTitle:@"Ok" otherButtonTitles:nil] show];
            }
        }];
    }
}

- (void)tapDone {
    NSString* err=nil;
    if (self.old.text.length < Password.minLength) {
        err = $str(@"Password must have at least %d characters", [Password minLength]);
    }
    if (![[Password i] quickCheckOldPassword:self.old.text]) {
        err = @"Old password is incorrect";
    }
    if (self.pass1.text.length < Password.minLength) {
        err = $str(@"Password must have at least %d characters", [Password minLength]);
    }
    if (!$eql(self.pass1.text, self.pass2.text)) {
        err = @"You must enter the new password twice";
    }
    if (err) {
        [[[UIAlertView alloc] initWithTitle:@"Error" message:err delegate:nil cancelButtonTitle:@"Ok" otherButtonTitles:nil] show];
        return;
    }

    [[[UIAlertView alloc] initWithTitle:nil message:@"Are you sure you wish to change your password?" delegate:self cancelButtonTitle:@"Cancel" otherButtonTitles:@"Change Password", nil] show];
}

#pragma mark - View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    [self.old becomeFirstResponder];
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

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    if (textField == self.old) [self.pass1 becomeFirstResponder];
    if (textField == self.pass1) [self.pass2 becomeFirstResponder];
    if (textField == self.pass2) [self tapDone];
    return NO;
}

@end
