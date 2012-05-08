//
//  GroupTable.m
//  Passwords
//
//  Created by Chris Hulbert on 20/02/12.
//  Copyright (c) 2012 Splinter Software. All rights reserved.
//

#import "GroupTable.h"
#import "Group.h"
#import "Password.h"
#import "AddEditEntry.h"
#import "Items.h"
#import "Item.h"
#import "Refresh.h"
#import "ConciseKit.h"
#import "ViewItem.h"
#import "MyHelpers.h"
#import "DropboxSDK.h"

@interface GroupTable() {
    NSArray* items;
}
@end

@implementation GroupTable
@synthesize group;

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark - Add items

- (void)tapAdd {
    if ([Password requirePasswordFrom:self]) return;
    
    // Present the 'new item screen'
    AddEditEntry* c = [[AddEditEntry alloc] initWithNibName:@"AddEditEntry" bundle:nil];
    c.group = self.group;
    UINavigationController* n = [[UINavigationController alloc] initWithRootViewController:c];
    [self presentModalViewController:n animated:YES];
}

#pragma mark - Refreshing

- (void)refresh {
    items = [Items getItemsForGroup:self.group];
    [self.tableView reloadData];
}

- (void)refreshNotify:(NSNotification*)n {
    [self refresh];
}

#pragma mark - View lifecycle

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // Use the glyphish mini icons (20x20px) for toolbar icons
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:(UIBarButtonSystemItemAdd) target:self action:@selector(tapAdd)];

    // Refresh, and listen for refresh notifications
    [self refresh];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(refreshNotify:) name:refreshNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(refreshNotify:) name:refreshItemsNotification object:nil];
}

- (void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex {
    if (buttonIndex == alertView.firstOtherButtonIndex) {
        [[DBSession sharedSession] link];
    }
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    // If this is the first time the app is run, explain where they can get help. This code is here instead of the app delegate because we can't show an alert during startup 
    static BOOL hasSeenInitialHelp = NO;
    if (!hasSeenInitialHelp && ![Items areAnyItems]) {
        hasSeenInitialHelp = YES;
        
        // Strongly suggest first thing to do is link to dropbox
        [[[UIAlertView alloc] initWithTitle:@"Welcome to Skeleton Key"
                                    message:@"First up, you should link to your Dropbox account (optional).\n"
          "After that, you can tap '+' (top right) to start saving passwords.\n"
          "For help and settings, tap on the top-left button.\n"
          "Thanks for using my app - Chris"
                                   delegate:self cancelButtonTitle:@"Skip" otherButtonTitles:@"Dropbox", nil] show];
    }
}


- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

#pragma mark - Table view data source

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    [MyHelpers setNoRowsMessage:tableView show:!items.count message:@"You have no items in this\ngroup. Tap the '+' icon\n(top right) to make one."];
    return items.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"Cell";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
    }
    
    // Configure the cell...
    cell.textLabel.text = [[items $at:indexPath.row] $at:1];
    
    return cell;
}

/*
// Override to support conditional editing of the table view.
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Return NO if you do not want the specified item to be editable.
    return YES;
}
*/

/*
// Override to support editing the table view.
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        // Delete the row from the data source
        [tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationFade];
    }   
    else if (editingStyle == UITableViewCellEditingStyleInsert) {
        // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
    }   
}
*/

/*
// Override to support rearranging the table view.
- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath
{
}
*/

/*
// Override to support conditional rearranging of the table view.
- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Return NO if you do not want the item to be re-orderable.
    return YES;
}
*/

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    // What did they tap?
    int itemId = [[[items $at:indexPath.row] $at:0] intValue];
    Item* i = [Item loadItemById:itemId];
    if (!i) { // Couldn't load or decrypt or something
        [[[UIAlertView alloc] initWithTitle:@"Error" message:@"Could not open this item!" delegate:nil cancelButtonTitle:@"Ok" otherButtonTitles:nil] show];
        return;
    }
    
    // View it
    ViewItem* vi = [[ViewItem alloc] initWithStyle:(UITableViewStyleGrouped)];
    vi.item = i;
    [self.navigationController pushViewController:vi animated:YES];
}

@end
