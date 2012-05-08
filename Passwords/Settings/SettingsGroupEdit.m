//
//  SettingsGroupEdit.m
//  Passwords
//
//  Created by Chris Hulbert on 15/02/12.
//  Copyright (c) 2012 Splinter Software. All rights reserved.
//

#import "SettingsGroupEdit.h"
#import "Group.h"
#import "Groups.h"
#import "ConciseKit.h"
#import <QuartzCore/QuartzCore.h>
#import "MyYaml.h"

#define tagColour 1000
#define tagIcon   2000

@implementation SettingsGroupEdit
@synthesize name, group, originalGroup;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
        self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:(UIBarButtonSystemItemSave) target:self action:@selector(tapSave)];
    }
    return self;
}

#pragma mark - Save / Create

- (void)tapSave {
    if (!self.name.text.length) {
        [[[UIAlertView alloc] initWithTitle:nil message:@"I need you to enter a group name" delegate:nil cancelButtonTitle:@"Ok" otherButtonTitles:nil] show];
        return;
    }
    
    self.group.name = self.name.text;
    // Create an ID if it's a new one
    if (!self.originalGroup) {
        // Generate until finds a unique one
        BOOL alreadyUsed;
        do {
            self.group.id = arc4random()%1000000;
            alreadyUsed = NO;
            for (Group* g in [Groups i].groups) {
                if (g.id==self.group.id) {
                    alreadyUsed = YES;
                }
            }
        } while (alreadyUsed);
    }
    
    [self.group save];
    if (!self.originalGroup) {
        [[Groups i] addGroup:self.group];
    }
    [self.navigationController popViewControllerAnimated:YES];
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    [textField resignFirstResponder];
    return NO;
}

#pragma mark - Colours

// Highlights the selected colour
- (void)setSelectedColour {
    for (UIButton* b in self.view.subviews) {
        if (tagColour<=b.tag && b.tag<=tagColour+360) {
            int butHue = b.tag - tagColour;
            b.layer.borderWidth = butHue==self.group.hue ? 2 : 0;
        }
    }
}

- (IBAction)tapColour:(id)sender {
    self.group.hue = ((UIView*)sender).tag-tagColour;
    [self setSelectedColour];
}

- (void)addColours {
    // Do the 12 points of the colour wheel?
    for (int i=0;i<12;i++) {
        UIButton* b = [UIButton buttonWithType:(UIButtonTypeCustom)];
        int hue=30*i;
        b.backgroundColor = [UIColor colorWithHue:hue/360.0 saturation:1 brightness:1 alpha:1];
        b.layer.borderColor = [UIColor blackColor].CGColor;
        b.frame = CGRectMake(22+23*i, 59, 23, 40);
        b.tag = tagColour+hue;
        [b addTarget:self action:@selector(tapColour:) forControlEvents:(UIControlEventTouchUpInside)];
        [self.view addSubview:b];
    }
    
    [self setSelectedColour];
}

#pragma mark - Icons

- (void)setSelectedIcon:(BOOL)anim {
    for (UIButton* b in scroll.subviews) {
        if (b.tag==tagIcon) {
            NSString* i = [iconButtonFilenames $for:[NSValue valueWithNonretainedObject:b]];
            BOOL match = $eql(i, group.icon);
            b.layer.borderWidth = match ? 2 : 0;
            if (match) {
                [((UIScrollView*)b.superview) scrollRectToVisible:CGRectInset(b.frame, -50, -50) animated:anim];
            }
        }
    }
}

- (IBAction)tapIcon:(id)sender {
    UIButton* b = sender;
    NSString* i = [iconButtonFilenames $for:[NSValue valueWithNonretainedObject:b]];
    group.icon = i;
    [self setSelectedIcon:YES];
}

- (void)addIcons {
    NSDictionary* yaml = [@"Icons.yaml" readBundleFileAsYaml];
    NSArray* icons = [yaml $for:@"icons"];
    
    scroll = [[UIScrollView alloc] init];
    scroll.frame = CGRectMake(20, 107, 285, self.view.frame.size.height-117);
    [self.view addSubview:scroll];
    
    // Set a random one if there is none set, eg a new group
    if (!self.group.icon.length) {
        self.group.icon = [icons objectAtIndex:arc4random()%icons.count];
    }
    
    iconButtonFilenames = [NSMutableDictionary dictionary];
    int x=0,y=0;
    for (NSString* i in icons) {
        UIImage* img = [UIImage imageNamed:i];
        UIButton* b = [UIButton buttonWithType:(UIButtonTypeCustom)];
        b.frame = CGRectMake(x*35, y*35, 35, 35);
        b.tag = tagIcon;
        [b setImage:img forState:(UIControlStateNormal)];
        [b addTarget:self action:@selector(tapIcon:) forControlEvents:(UIControlEventTouchUpInside)];
        b.layer.borderColor = [UIColor blackColor].CGColor;
        
        [scroll addSubview:b];
        scroll.contentSize = CGSizeMake(scroll.frame.size.width, CGRectGetMaxY(b.frame));
        
        [iconButtonFilenames setObject:i forKey:[NSValue valueWithNonretainedObject:b]];
        
        x++;
        if (x>=8) {
            x=0;
            y++;
        }
    }
    
    [self setSelectedIcon:NO];
}

#pragma mark - View lifecycle

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.title = self.originalGroup ? @"Edit Group" : @"New Group";
    self.group = self.originalGroup ?: [[Group alloc] init];
    
    // Choose a random colour if it's a new one
    if (!self.originalGroup) {
        self.group.hue = (arc4random()%12)*30;
    }

    // Do any additional setup after loading the view from its nib.
    self.name.text = self.group.name;
    [self addColours];
    [self addIcons];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
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

@end
