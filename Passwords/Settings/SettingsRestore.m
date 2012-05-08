//
//  SettingsRestore.m
//  Passwords
//
//  Created by Chris Hulbert on 9/03/12.
//  Copyright (c) 2012 Splinter Software. All rights reserved.
//

#import "SettingsRestore.h"
#import "Password.h"
#import "Backups.h"
#import "ConciseKit.h"
#import "DropboxClearer.h"
#import "CHBgDropboxSync.h"
#import "Refresh.h"

@implementation SettingsRestore

@synthesize password;
@synthesize backupYmd;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        self.title = @"Restore Backup";
        self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Restore" style:(UIBarButtonItemStyleDone) target:self action:@selector(tapRestore)];
        self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:(UIBarButtonSystemItemCancel) target:self action:@selector(tapCancel)];
    }
    return self;
}

- (void)tapCancel {
    [self dismissModalViewControllerAnimated:YES];
}

#pragma mark - View lifecycle

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self.password becomeFirstResponder];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

#pragma mark - Restore!

- (void)tapRestore {
    // Check password
    NSString* passwordPath = [[[Backups backupPath] stringByAppendingPathComponent:self.backupYmd] stringByAppendingPathComponent:@"password.yaml"];
    if (![[NSFileManager defaultManager] fileExistsAtPath:passwordPath]) {
        [[[UIAlertView alloc] initWithTitle:@"Error" message:@"Cannot restore - this backup doesn't have a master password" delegate:nil cancelButtonTitle:@"Ok" otherButtonTitles:nil] show];
        return;
    }
    if ([[Password i] quickCheckOldPassword:self.password.text fromFile:passwordPath]) {
        // OK
        [[[UIActionSheet alloc] initWithTitle:@"Restoring will nuke your current data, both here and on Dropbox. Are you sure?" delegate:self cancelButtonTitle:@"Cancel" destructiveButtonTitle:@"Restore!" otherButtonTitles:nil] showInView:self.view];
    } else {
        [[[UIAlertView alloc] initWithTitle:@"Error" message:@"The password doesn't match the master password as at the time this backup was made." delegate:nil cancelButtonTitle:@"Ok" otherButtonTitles:nil] show];
    }
}

- (void)actionSheet:(UIActionSheet *)actionSheet didDismissWithButtonIndex:(NSInteger)buttonIndex {
    if (buttonIndex == actionSheet.destructiveButtonIndex) {
        // Do the restore!!!
        // The strategy is this: stop syncing, clear dropbox, clear the last sync data, restore, then start the sync which will then push everything up to dropbox.
        [CHBgDropboxSync forceStopIfRunning];
        UIAlertView* clearing = [[UIAlertView alloc] initWithTitle:nil message:@"Clearing Dropbox" delegate:nil cancelButtonTitle:nil otherButtonTitles:nil];
        [clearing show];
        [CHBgDropboxSync clearLastSyncData]; // Clear the last sync data so that after the restore, everything will be pushed to dropbox. Also clear the last sync data *before* clearing dropbox so that if the clearing fails half way, it'll push the cleared files back up dropbox rather than deleting them locally next time it tries syncing.
        [DropboxClearer doClear:^(BOOL success) { // Erase everything on dropbox
            [clearing dismissWithClickedButtonIndex:0 animated:YES];
            if (success) {
                [Backups doRestore:self.backupYmd];  // Restore
                [Refresh sendRefresh]; // So the app re-loads the tabs
                [CHBgDropboxSync start]; // Start sync again
                [[Password i] validatePassword:self.password.text]; // Re-generate the key by the new password so we can decrypt stuff
                [self dismissModalViewControllerAnimated:YES];
                [[[UIAlertView alloc] initWithTitle:@"Restored Backup" message:$str(@"%@ was restored successfully", self.backupYmd) delegate:nil cancelButtonTitle:nil otherButtonTitles:@"Ok", nil] show];                
            } else {
                [[[UIAlertView alloc] initWithTitle:@"Error" message:@"Couldn't clear dropbox, restore cancelled." delegate:nil cancelButtonTitle:@"Ok" otherButtonTitles:nil] show];
            }
        }];
    }
}


- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    [self tapRestore];
    return NO;
}

@end
