//
//  GroupChooser.m
//  Passwords
//
//  Created by Chris Hulbert on 22/02/12.
//  Copyright (c) 2012 Splinter Software. All rights reserved.
//

#import "GroupChooser.h"
#import "Groups.h"
#import "Group.h"

@implementation GroupChooser
@synthesize selectedGroup;
@synthesize success;

#pragma mark - View lifecycle

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
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
    Group* g = [[Groups i].groups objectAtIndex:indexPath.row];
    cell.textLabel.text = g.name;
    cell.accessoryType = g==selectedGroup ? UITableViewCellAccessoryCheckmark : 0;
    
    return cell;
}

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    Group* g = [[Groups i].groups objectAtIndex:indexPath.row];
    success(g);
    [self.navigationController popViewControllerAnimated:YES];
}

@end
