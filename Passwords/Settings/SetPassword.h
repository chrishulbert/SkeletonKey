//
//  SetPassword.h
//  Passwords
//
//  Created by Chris Hulbert on 17/02/12.
//  Copyright (c) 2012 Splinter Software. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface SetPassword : UIViewController<UITextFieldDelegate, UIAlertViewDelegate>

@property(assign) IBOutlet UITextField* password1;
@property(assign) IBOutlet UITextField* password2;

@end
