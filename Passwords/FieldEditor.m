//
//  FieldEditor.m
//  Passwords
//
//  Created by Chris Hulbert on 22/02/12.
//  Copyright (c) 2012 Splinter Software. All rights reserved.
//

#import "FieldEditor.h"

@implementation FieldEditor

@synthesize fieldName, fieldValue, success, originalName, originalValue;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
        
        self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:(UIBarButtonSystemItemDone) target:self action:@selector(tapDone)];
    }
    return self;
}

- (void)tapDone {
    if (!fieldName.text.length) {
        [self.fieldName becomeFirstResponder];
        [[[UIAlertView alloc] initWithTitle:nil message:@"You'll need to enter a field name first" delegate:nil cancelButtonTitle:@"Ok" otherButtonTitles:nil] show];
        return;
    }
    if (!fieldValue.text.length) {
        [self.fieldValue becomeFirstResponder];
        [[[UIAlertView alloc] initWithTitle:nil message:@"You'll need to enter a value first" delegate:nil cancelButtonTitle:@"Ok" otherButtonTitles:nil] show];
        return;
    }
    success(fieldName.text, fieldValue.text);
    [self.navigationController popViewControllerAnimated:YES];
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    if (textField==fieldName) [fieldValue becomeFirstResponder];
    if (textField==fieldValue) [self tapDone];
    return NO;
}

#pragma mark - View lifecycle

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.fieldName.text = originalName;
    self.fieldValue.text = originalValue;
    
    if (originalName.length) {
        [self.fieldValue becomeFirstResponder];
    } else {
        [self.fieldName becomeFirstResponder];
    }
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

@end
