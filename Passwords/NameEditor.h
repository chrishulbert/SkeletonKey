//
//  NameEditor.h
//  Passwords
//
//  Created by Chris Hulbert on 23/02/12.
//  Copyright (c) 2012 Splinter Software. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef void(^NameEditorDone)(NSString* name);

@interface NameEditor : UIViewController<UITextFieldDelegate>

@property(weak) IBOutlet UITextField* textField;
@property(copy) NameEditorDone success;
@property(strong) NSString* originalName;

@end
