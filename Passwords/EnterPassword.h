//
//  EnterPassword.h
//  Passwords
//
//  Created by Chris Hulbert on 23/02/12.
//  Copyright (c) 2012 Splinter Software. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface EnterPassword : UIViewController<UITextFieldDelegate>

@property(weak) IBOutlet UITextField* pass;
@property(assign) BOOL hideKeyboard;

@end
