//
//  EnterPin.h
//  Passwords
//
//  Created by Chris Hulbert on 27/02/12.
//  Copyright (c) 2012 Splinter Software. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface EnterPin : UIViewController<UITextFieldDelegate, UIAlertViewDelegate>

@property(weak) IBOutlet UITextField* pin;
@property(assign) BOOL hideKeyboard;

@end
