//
//  ViewItem.m
//  Passwords
//
//  Created by Chris Hulbert on 24/02/12.
//  Copyright (c) 2012 Splinter Software. All rights reserved.
//

#import "ViewItem.h"
#import "Item.h"
#import "Items.h"
#import "AddEditEntry.h"

@interface ViewItem() {
    NSString* actionSheetClipboardItem;
}
@end

@implementation ViewItem
@synthesize item;

- (id)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:style];
    if (self) {
        // Custom initialization
        self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:(UIBarButtonSystemItemEdit) target:self action:@selector(tapEdit)];
    }
    return self;
}

- (void)tapEdit {
    AddEditEntry* ae = [[AddEditEntry alloc] initWithNibName:@"AddEditEntry" bundle:nil];
    ae.originalItem = self.item;
    ae.title = @"Edit Item";
    [self.navigationController pushViewController:ae animated:YES];
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
    self.title = self.item.name;
    [self.tableView reloadData];
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
    // Hide the notes section if there are none
    return item.notes.length ? 2 : 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (section==0) {
        return item.fields.count;
    }
    if (section==1) {
        return 1;
    }
    return 0;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    if (section==0) {
        if (item.fields.count) {
            return nil;
        } else {
            return @"No fields, tap 'edit' to add.";
        }
    }
    if (section==1) return @"Notes";
    return 0;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    int s=indexPath.section;
    int r=indexPath.row;
    UITableViewCellStyle style = s==1 ? UITableViewCellStyleSubtitle : UITableViewCellStyleValue2;
    UITableViewCell *cell = [[UITableViewCell alloc] initWithStyle:style reuseIdentifier:nil];
    
    if (s==0) {
        cell.textLabel.text = [[item.fields objectAtIndex:r] objectAtIndex:0];
        cell.detailTextLabel.text = [[item.fields objectAtIndex:r] objectAtIndex:1];
    }
    if (s==1) {
        cell.detailTextLabel.text = item.notes;
        cell.detailTextLabel.numberOfLines = 0;
        cell.detailTextLabel.lineBreakMode = UILineBreakModeWordWrap;
    }
    
    return cell;
}

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section==1) {
        cell.detailTextLabel.textColor = [UIColor blackColor];
    }
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section==1 && self.item.notes.length) {
        CGSize s = [item.notes sizeWithFont:[UIFont systemFontOfSize:14] constrainedToSize:CGSizeMake(274, 999) lineBreakMode:(UILineBreakModeWordWrap)];
        return MAX(tableView.rowHeight, s.height+2*14); // 14 px buffer top and bottom
    }
    return tableView.rowHeight;
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
    int s=indexPath.section;
    int r=indexPath.row;
    if (s==0) {
        UIActionSheet* as = [[UIActionSheet alloc] initWithTitle:[[item.fields objectAtIndex:r] objectAtIndex:0]
                                                        delegate:self
                                               cancelButtonTitle:@"Cancel"
                                          destructiveButtonTitle:nil
                                               otherButtonTitles:@"Copy to clipboard", nil];
        [as showFromTabBar:self.tabBarController.tabBar];
        actionSheetClipboardItem = [[item.fields objectAtIndex:r] objectAtIndex:1];
    }
    if (s==1) {
        UIActionSheet* as = [[UIActionSheet alloc] initWithTitle:@"Notes"
                                                        delegate:self
                                               cancelButtonTitle:@"Cancel" destructiveButtonTitle:nil otherButtonTitles:@"Copy to clipboard", nil];
        [as showFromTabBar:self.tabBarController.tabBar];
        actionSheetClipboardItem = item.notes;
    }
}

// Called when a button is clicked. The view will be automatically dismissed after this call returns
- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex {
    if (buttonIndex==actionSheet.firstOtherButtonIndex) {
        [UIPasteboard generalPasteboard].string = actionSheetClipboardItem;
    }
}

- (void)actionSheet:(UIActionSheet *)actionSheet willDismissWithButtonIndex:(NSInteger)buttonIndex {
    [self.tableView deselectRowAtIndexPath:self.tableView.indexPathForSelectedRow animated:YES];
    actionSheetClipboardItem = nil;
}

@end
