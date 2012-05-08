//
//  AddEditEntry.m
//  Passwords
//
//  Created by Chris Hulbert on 22/02/12.
//  Copyright (c) 2012 Splinter Software. All rights reserved.
//

#import "AddEditEntry.h"
#import "ConciseKit.h"
#import "Group.h"
#import "GroupChooser.h"
#import "FieldEditor.h"
#import "Item.h"
#import "Groups.h"
#import "NameEditor.h"
#import "NotesEditor.h"
#import "Refresh.h"
#import "CHBgDropboxSync.h"
#import "Items.h"

@interface AddEditEntry() {
    NSString* name;
    NSString* notes;
    NSMutableArray* fields;
    BOOL shownFirstItemHelp;
}
@end

@implementation AddEditEntry
@synthesize group, originalItem;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    if (self=[super initWithNibName:nibNameOrNil bundle:nibBundleOrNil]) {
        self.title = @"New Item";
                
        self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:(UIBarButtonSystemItemSave)                                                                                                target:self action:@selector(tapSave)];
    }
    return self;
}

- (void)tapSave {
    if (!name.length) {
        [[[UIAlertView alloc] initWithTitle:nil message:@"I need you to enter a name" delegate:nil cancelButtonTitle:@"Ok" otherButtonTitles:nil] show];
        return;
    }

    Item* i = self.originalItem ?: [[Item alloc] init];
    
    // Create an ID if it's a new one
    if (!self.originalItem) {
        BOOL alreadyUsed;
        do {
            i.id = arc4random()%1000000;
            alreadyUsed = [[NSFileManager defaultManager] fileExistsAtPath:i.filePath];
        } while (alreadyUsed);
    }
    
    i.name = name;
    i.groupId = self.group.id;
    i.fields = fields;
    i.notes = notes.length ? notes : nil;
    [i save];
    
    // Tell the UI to reflect this new item
    [Refresh sendRefreshItemsNotGroups];
    // Sync the new/changed entry
    [CHBgDropboxSync start];
    
    // Close me
    if (self.originalItem) {
        [self.navigationController popViewControllerAnimated:YES];
    } else {
        [self dismissModalViewControllerAnimated:YES];
    }
}


#pragma mark - View lifecycle

- (void)tapClose {
    [self dismissModalViewControllerAnimated:YES];
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    // Only make a 'cancel' button if i'm not pushed onto a stack that'll give me a 'back'
    if (self.navigationController.viewControllers.count<=1) {
        self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:(UIBarButtonSystemItemCancel) target:self action:@selector(tapClose)];
    }

    if (self.originalItem) {
        // Edit
        name = self.originalItem.name;
        notes = self.originalItem.notes;
        fields = [NSMutableArray arrayWithArray:self.originalItem.fields];
        self.group = [[Groups i] groupById:self.originalItem.groupId];
    } else {
        // New!
        name = nil;
        notes = nil;
        fields = $marr($marr(@"Login", @""), $marr(@"Password", @""));
    }
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
}

- (void)viewDidAppear:(BOOL)animated {
    [self.tableView deselectRowAtIndexPath:self.tableView.indexPathForSelectedRow animated:YES];
    [super viewDidAppear:animated];
    
    // If there are no items, show some help
    if (![Items areAnyItems] && !shownFirstItemHelp) {
        shownFirstItemHelp = YES;
        [[[UIAlertView alloc] initWithTitle:nil message:@"To add an item, you'll want to set it's name first. Tap on the 'name' row to do this. Once you've done that, you'll want to fill in the username and password fields, and add any extra fields that you may need. You may also enter any free-form notes that you want too." delegate:nil cancelButtonTitle:@"Ok" otherButtonTitles:nil] show];
    }
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
    // Return the number of sections.
    if (self.originalItem) 
        return 4; // for the extra 'delete' section
    else 
        return 3; // Group/Item name, Username/password/extra fields, notes,
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (section==0) return self.originalItem ? 2 : 1;
    if (section==1) return fields.count+1;
    if (section==2) return 1;
    if (section==3) return 1;
    return 0;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    if (section==1) return @"Fields";
    if (section==2) return @"Notes";
    return nil;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    int s = indexPath.section;
    int r = indexPath.row;

    UITableViewCellStyle style = s>=2 ? UITableViewCellStyleSubtitle : UITableViewCellStyleValue2;
    UITableViewCell* cell = [[UITableViewCell alloc] initWithStyle:style reuseIdentifier:nil];
    cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    
    // Configure the cell...
    if (s==0 && r==0) {
        cell.textLabel.text = @"Name";
        cell.detailTextLabel.text = name;
    }
    if (s==0 && r==1) {
        cell.textLabel.text = @"Group";
        cell.detailTextLabel.text = self.group.name;
    }
    if (s==1) {
        if (r<fields.count) {
            cell.textLabel.text = [[fields objectAtIndex:r] objectAtIndex:0];
            cell.detailTextLabel.text = [[fields objectAtIndex:r] objectAtIndex:1];
        } else {
            cell.textLabel.text = @"Add field";
        }
    }
    if (s==2 && r==0) {
        cell.detailTextLabel.text = notes.length ? notes : @"none";
        cell.detailTextLabel.numberOfLines = 0;
        cell.detailTextLabel.lineBreakMode = UILineBreakModeWordWrap;
    }
    if (s==3) {
        cell.textLabel.text = @"Delete";
        cell.accessoryType = 0;
    }
    
    return cell;
}

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section==2) {
        cell.detailTextLabel.textColor = notes.length ? [UIColor blackColor] : [UIColor grayColor];
    }
    if (indexPath.section==3) {
        cell.backgroundColor = [UIColor colorWithPatternImage:[UIImage imageNamed:@"red"]];
        cell.textLabel.textColor = [UIColor whiteColor];
        cell.textLabel.backgroundColor = [UIColor clearColor];
    }
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section==2 && notes.length) {
        CGSize s = [notes sizeWithFont:[UIFont systemFontOfSize:14] constrainedToSize:CGSizeMake(260, 999) lineBreakMode:(UILineBreakModeWordWrap)];
        return MAX(tableView.rowHeight, s.height+2*14); // 14 px buffer top and bottom
    }
    return tableView.rowHeight;
}

// Override to support conditional editing of the table view.
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    return indexPath.section==1 && indexPath.row<fields.count; // Only can delete fields
}

// Override to support editing the table view.
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        // Delete the row from the data source
        [fields removeObjectAtIndex:indexPath.row];
        [tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationFade];
    }   
    else if (editingStyle == UITableViewCellEditingStyleInsert) {
        // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
    }   
}

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
    int s = indexPath.section;
    int r = indexPath.row;
    
    if (s==0 && r==0) { // Name
        NameEditor* ne = [[NameEditor alloc] initWithNibName:@"NameEditor" bundle:nil];
        ne.originalName = name;
        ne.success = ^(NSString* newName) {
            name = newName;
            [self.tableView reloadData];
        };
        [self.navigationController pushViewController:ne animated:YES];
    }
    if (s==0 && r==1) {
        GroupChooser* gc = [[GroupChooser alloc] initWithStyle:(UITableViewStyleGrouped)];
        gc.selectedGroup = self.group;
        gc.title = @"Group";
        gc.success = ^(Group* selected) {
            self.group = selected;
            [self.tableView reloadData];
        };
        [self.navigationController pushViewController:gc animated:YES];
    }
    
    if (s==1) {
        if (r<fields.count) {
            FieldEditor* fe = [[FieldEditor alloc] initWithNibName:@"FieldEditor" bundle:nil];
            fe.title = @"Edit Field";
            fe.originalName = [[fields objectAtIndex:r] objectAtIndex:0];
            fe.originalValue = [[fields objectAtIndex:r] objectAtIndex:1]; 
            fe.success = ^(NSString* n, NSString* v) {
                [fields replaceObjectAtIndex:r withObject:$arr(n,v)];
                [self.tableView reloadData];
            };
            [self.navigationController pushViewController:fe animated:YES];
        } else {
            FieldEditor* fe = [[FieldEditor alloc] initWithNibName:@"FieldEditor" bundle:nil];
            fe.title = @"Add Field";
            fe.success = ^(NSString* n, NSString* v) {
                [fields addObject:$marr(n,v)];
                [self.tableView reloadData];
            };
            [self.navigationController pushViewController:fe animated:YES];
        }
    }
    if (s==2) {
        NotesEditor* ne = [[NotesEditor alloc] initWithNibName:@"NotesEditor" bundle:nil];
        ne.originalNotes = notes;
        ne.success = ^(NSString* newNote) {
            notes = newNote.length ? [newNote stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]] : nil;
            [self.tableView reloadData];
        };
        [self.navigationController pushViewController:ne animated:YES];
    }
    if (s==3) {
        // Delete!
        [[[UIActionSheet alloc] initWithTitle:name delegate:self cancelButtonTitle:@"Cancel" destructiveButtonTitle:@"Delete this item" otherButtonTitles:nil] showFromTabBar:self.tabBarController.tabBar];
    }
}


// Called when a button is clicked. The view will be automatically dismissed after this call returns
- (void)actionSheet:(UIActionSheet *)actionSheet didDismissWithButtonIndex:(NSInteger)buttonIndex {
    [self.tableView deselectRowAtIndexPath:self.tableView.indexPathForSelectedRow animated:YES];
    if (buttonIndex == actionSheet.destructiveButtonIndex) {
        // Kill it
        [self.originalItem deleteFile];
        // Tell the UI to reflect this new item
        [Refresh sendRefreshItemsNotGroups];
        // Pop to root, skipping the view page (since theres nothing to view anymore)
        [self.navigationController popToRootViewControllerAnimated:YES];
    }
}

@end
