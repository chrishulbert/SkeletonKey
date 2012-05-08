//
//  SettingsRoot.m
//  Passwords
//
//  Created by Chris Hulbert on 14/02/12.
//  Copyright (c) 2012 Splinter Software. All rights reserved.
//

#import "SettingsRoot.h"
#import "SettingsGroups.h"
#import "AppDelegate.h"
#import "ChangePassword.h"
#import "Password.h"
#import "SetPin.h"
#import "DropboxSDK.h"
#import "Refresh.h"
#import "SettingsBackups.h"
#import "CHBgDropboxSync.h"
#import "MoreApps.h"
#import "Help.h"

@implementation SettingsRoot

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        self.title = @"Skeleton Key"; // Don't have 'settings' in the title, because it's right underneath in the group header
        self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"tbar_key"] style:(UIBarButtonItemStyleBordered) target:self action:@selector(tapClose)];
        self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Close" style:(UIBarButtonItemStyleBordered) target:self action:@selector(tapClose)];
//                                                 initWithImage:[UIImage imageNamed:@"tbar_key"] style:(UIBarButtonItemStyleBordered) target:self action:@selector(tapClose)];
        self.navigationItem.backBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Back" style:(UIBarButtonItemStyleBordered) target:nil action:nil];
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(refreshNotify:) name:refreshNotification object:nil];

    }
    return self;
}

- (void)tapClose {
    [[AppDelegate i] aboutToReturnFromSettings];
    [self dismissModalViewControllerAnimated:YES];
}

#pragma mark - Refreshing eg they've come back from a link

- (void)refreshNotify:(NSNotification*)n {
    [self.tableView reloadData];
}

#pragma mark - View lifecycle

- (void)viewWillAppear:(BOOL)animated {
    [self.tableView reloadData];
    [super viewWillAppear:animated];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

#pragma mark - Table view data source

-(NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    if (section==0) {
        return @"Settings";
    }
    if (section==1) {
        return @"Help";
    }
    return nil;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 2;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (section==0) { // Settings
        return 5;
    }
    if (section==1) { // Help
        return 2;
    }
    return 0;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *CellIdentifier = @"Cell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:CellIdentifier];
    }
    
    // Configure the cell...
    cell.textLabel.text = nil;
    cell.detailTextLabel.text = nil;
    cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    
    if (indexPath.section==0) {
        if (indexPath.row==0) {
            cell.textLabel.text = @"Groups";
            cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
        }
        if (indexPath.row==1) {
            cell.textLabel.text = Password.passwordHasBeenSet ? @"Change master password" : @"Set master password";
            cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
        }
        if (indexPath.row==2) {
            cell.textLabel.text = Password.pinSet ? @"Remove PIN" : @"Set PIN";
            cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
        }
        if (indexPath.row==3) {
            cell.textLabel.text = @"Dropbox";
            BOOL isLinked = [[DBSession sharedSession] isLinked];
            cell.detailTextLabel.text = isLinked ? @"Linked" : @"Not linked";
        }
        if (indexPath.row==4) {
            cell.textLabel.text = @"Backups";
        }
    }
    if (indexPath.section==1) {
        if (indexPath.row==0) {
            cell.textLabel.text = @"Help";
            cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
        }
        if (indexPath.row==1) {
            cell.textLabel.text = @"More apps by this developer";
            cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
        }
    }
    
    return cell;
}

#pragma mark - Table view delegate

#define alertTagPINRemoval     1
#define alertTagUnlink         2
#define alertTagChangePassword 3

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    if (alertView.tag==alertTagUnlink && buttonIndex==alertView.firstOtherButtonIndex) {
        [CHBgDropboxSync forceStopIfRunning];
        [CHBgDropboxSync clearLastSyncData];
        [[DBSession sharedSession] unlinkAll];
        [self.tableView reloadData];
    }
    if (alertView.tag==alertTagPINRemoval && buttonIndex==alertView.firstOtherButtonIndex) {
        [Password pinRemove];
        [self.tableView reloadData];
    }
    if (alertView.tag==alertTagChangePassword && buttonIndex==alertView.firstOtherButtonIndex) {
        [self.navigationController pushViewController:[[ChangePassword alloc] initWithNibName:@"ChangePassword" bundle:nil] animated:YES];
    }
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    if (indexPath.section==0) {
        if (indexPath.row==0) {
            [self.navigationController pushViewController:[[SettingsGroups alloc] initWithStyle:UITableViewStyleGrouped] animated:YES];
        }
        if (indexPath.row==1) {
            // Call the password *setter* if it hasn't been called before, in lieu of the password *changer*
            if ([Password requirePasswordFrom:self]) return;
            
            // Now change it
            UIAlertView* a = [[UIAlertView alloc]
                              initWithTitle:@"Changing passwords"
                              message:@"* Please sync all your devices with this app to Dropbox first.\n" 
                              "* Be aware that this will nuke your Dropbox folder, re-encrypt everything, and re-upload everything.\n"
                              "* Please only do this whilst on wifi, so the Dropbox sync can go smoothly.\n"
                              "* Only change the master password on one device.\n"
                              "* Sync all your other devices after the password change.\n"
                              "* If any part of the sync process fails and corrupts your data, you can always restore a backup from the settings page."
                              delegate:self cancelButtonTitle:@"Cancel" otherButtonTitles:@"Continue", nil];
            a.tag = alertTagChangePassword;
            [a show];
        }
        if (indexPath.row==2) {
            // Requires a password first
            if ([Password requirePasswordFrom:self]) return;
            
            // If theres a pin set, remove it
            if (Password.pinSet) {
                UIAlertView* a = [[UIAlertView alloc] initWithTitle:nil message:@"Remove the PIN and revert to using the master password for authentication?" delegate:self cancelButtonTitle:@"Cancel" otherButtonTitles:@"Remove PIN", nil];
                a.tag = alertTagPINRemoval;
                [a show];
            } else {
                // Call the PIN setter/remover
                [self.navigationController pushViewController:[[SetPin alloc] initWithNibName:@"SetPin" bundle:nil] animated:YES];
            }
        }
        if (indexPath.row==3) {
            BOOL isLinked = [[DBSession sharedSession] isLinked];
            if (isLinked) {
                UIAlertView* a = [[UIAlertView alloc] initWithTitle:@"Dropbox" message:@"Unlink this app from your Dropbox account?" delegate:self cancelButtonTitle:@"Cancel" otherButtonTitles:@"Unlink", nil];
                a.tag = alertTagUnlink;
                [a show];
            } else {
                [[DBSession sharedSession] link];
            }
        }
        if (indexPath.row==4) {
            // Backups
            [self.navigationController pushViewController:[[SettingsBackups alloc] initWithNibName:@"SettingsBackups" bundle:nil] animated:YES];
        }
    }
    if (indexPath.section==1) {
        if (indexPath.row==0) {
            [self.navigationController pushViewController:[[Help alloc] initWithNibName:@"Help" bundle:nil] animated:YES];
        }
        if (indexPath.row==1) {
            [self.navigationController pushViewController:[[MoreApps alloc] initWithNibName:@"MoreApps" bundle:nil] animated:YES];
        }
    }

}

@end
