//
//  ChangePassword.h
//  Passwords
//
//  Created by Chris Hulbert on 26/02/12.
//  Copyright (c) 2012 Splinter Software. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ChangePassword : UIViewController<UITextFieldDelegate, UIAlertViewDelegate>

@property(weak) IBOutlet UITextField* old;
@property(weak) IBOutlet UITextField* pass1;
@property(weak) IBOutlet UITextField* pass2;

@end
