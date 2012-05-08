//
//  SettingsGroups.m
//  Passwords
//
//  Created by Chris Hulbert on 14/02/12.
//  Copyright (c) 2012 Splinter Software. All rights reserved.
//

#import "SettingsGroups.h"
#import "Groups.h"
#import "Group.h"
#import "ConciseKit.h"
#import "SettingsGroupEdit.h"
#import "CHBgDropboxSync.h"

@implementation SettingsGroups

- (void)dealloc {
    [CHBgDropboxSync start]; // Re-sync any groups changes when you close the groups screen
}

- (id)initWithStyle:(UITableViewStyle)style {
    self = [super initWithStyle:style];
    if (self) {
        self.title = @"Groups";
        self.navigationItem.rightBarButtonItems = $arr(
            self.editButtonItem,
            [[UIBarButtonItem alloc] initWithBarButtonSystemItem:(UIBarButtonSystemItemAdd) target:self action:@selector(tapAdd)]);
    }
    return self;
}

- (void)tapAdd {
    SettingsGroupEdit* s = [[SettingsGroupEdit alloc] initWithNibName:@"SettingsGroupEdit" bundle:nil];
    [self.navigationController pushViewController:s animated:YES];
}

#pragma mark - View lifecycle

- (void)viewDidLoad {
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

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self.tableView reloadData];
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

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [Groups i].groups.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"Cell";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
    }
    
    // Configure the cell...
    Group* g = [[[Groups i] groups] objectAtIndex:indexPath.row];
    cell.textLabel.text = g.name;
    cell.imageView.image = [UIImage imageNamed:g.icon];
    
    return cell;
}

// This allows the swipe-to-delete
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        // Delete the row from the data source
        Group* g = [[[Groups i] groups] objectAtIndex:indexPath.row];
        [[Groups i] deleteGroup:g];
        [tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationFade];
    }   
    else if (editingStyle == UITableViewCellEditingStyleInsert) {
        // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
    }   
}

// Override to support rearranging the table view.
- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath {
    NSMutableArray* groups = [NSMutableArray arrayWithArray:[Groups i].groups];
    Group* g = [groups objectAtIndex:fromIndexPath.row];
    [groups removeObjectAtIndex:fromIndexPath.row];
    [groups insertObject:g atIndex:toIndexPath.row];
    [Groups i].groups = [NSArray arrayWithArray:groups];
    [[Groups i] saveSortOrder];
}

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    // Navigation logic may go here. Create and push another view controller.
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    Group* g = [[[Groups i] groups] objectAtIndex:indexPath.row];
    SettingsGroupEdit* s = [[SettingsGroupEdit alloc] initWithNibName:@"SettingsGroupEdit" bundle:nil];
    s.originalGroup = g;
    [self.navigationController pushViewController:s animated:YES];
}

@end
