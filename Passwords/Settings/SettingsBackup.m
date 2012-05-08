//
//  SettingsBackup.m
//  Passwords
//
//  Created by Chris Hulbert on 2/03/12.
//  Copyright (c) 2012 Splinter Software. All rights reserved.
//

#import "SettingsBackup.h"
#import "ConciseKit.h"
#import "Backups.h"
#import "SettingsRestore.h"

@implementation SettingsBackup
@synthesize backupYmd, groups, items;

- (id)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:style];
    if (self) {
        // Custom initialization
    }
    return self;
}

#pragma mark - View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];

    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
 
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
}

- (void)viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 3;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (section==0) return 1;
    if (section==1) return groups.count;
    if (section==2) return items.count;
    return 0;
}
- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    if (section==0) return nil;
    if (section==1) return @"Groups";
    if (section==2) return @"Items";
    return nil;
}

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section==0) {
        cell.backgroundColor = [UIColor colorWithPatternImage:[UIImage imageNamed:@"red"]];
        cell.textLabel.textColor = [UIColor whiteColor];
        cell.textLabel.backgroundColor = [UIColor clearColor];
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:nil];
    
    if (indexPath.section==0) {
        cell.textLabel.text = @"Restore this backup";
    }
    if (indexPath.section==1) {
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
        cell.textLabel.text = [groups $at:indexPath.row];
    }
    if (indexPath.section==2) {
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
        cell.textLabel.text = [items $at:indexPath.row];
    }
    
    return cell;
}

#pragma mark - Table view delegate

- (void)bringUpRestoreScreen {
    SettingsRestore* sr = [[SettingsRestore alloc] initWithNibName:@"SettingsRestore" bundle:nil];
    sr.backupYmd = self.backupYmd;
    UINavigationController* n = [[UINavigationController alloc] initWithRootViewController:sr];
    [self presentModalViewController:n animated:YES];
}

- (void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex {
    if (buttonIndex == alertView.firstOtherButtonIndex) {
        [self bringUpRestoreScreen];
    }
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [self.tableView deselectRowAtIndexPath:self.tableView.indexPathForSelectedRow animated:YES];
    if (indexPath.section==0) {
        // Notify them if this backups password is different
        if ([Backups doesHaveSamePassword:self.backupYmd]) {
            [self bringUpRestoreScreen];
        } else {
            [[[UIAlertView alloc] initWithTitle:nil message:@"This backup has a different password to the one you currently have set. You'll need to enter the password that was applicable when this backup was made on the next screen." delegate:self cancelButtonTitle:@"Cancel" otherButtonTitles:@"Ok", nil] show];
        }
    }
}

@end
