//
//  SetPin.h
//  Passwords
//
//  Created by Chris Hulbert on 27/02/12.
//  Copyright (c) 2012 Splinter Software. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface SetPin : UIViewController<UITextFieldDelegate>

@property(weak) IBOutlet UITextField* pin;

@end
