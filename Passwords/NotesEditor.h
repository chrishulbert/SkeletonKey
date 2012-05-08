//
//  NotesEditor.h
//  Passwords
//
//  Created by Chris Hulbert on 23/02/12.
//  Copyright (c) 2012 Splinter Software. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef void(^NotesEditorDone)(NSString* newNotes);

@interface NotesEditor : UIViewController

@property(weak) IBOutlet UITextView* notes;
@property(strong) NSString* originalNotes;
@property(copy) NotesEditorDone success;

@end
