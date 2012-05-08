//
//  FieldEditor.h
//  Passwords
//
//  Created by Chris Hulbert on 22/02/12.
//  Copyright (c) 2012 Splinter Software. All rights reserved.
//

#import <UIKit/UIKit.h>


typedef void(^FieldEditorSuccess)(NSString* name, NSString* value);

@interface FieldEditor : UIViewController<UITextFieldDelegate>

@property(weak) IBOutlet UITextField* fieldName;
@property(weak) IBOutlet UITextField* fieldValue;

@property(strong) NSString* originalName;
@property(strong) NSString* originalValue;

@property(copy) FieldEditorSuccess success;

@end
