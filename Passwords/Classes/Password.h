//
//  Password.h
//  Passwords
//
//  Created by Chris Hulbert on 20/02/12.
//  Copyright (c) 2012 Splinter Software. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface Password : NSObject

+ (Password*)i;
+ (int)minLength;
// Returns YES if they have no password and brings up the password setter
// The idea is that, before adding a password etc, you do: if ([Password requirePasswordFrom:self]) return;
+ (BOOL)requirePasswordFrom:(UIViewController*)vc;
+ (BOOL)passwordHasBeenSet;

- (void)appGoingToBackground;
- (void)setPassword:(NSString*)clearPassword;
- (NSString*)changePasswordFrom:(NSString*)oldPassword to:(NSString*)newPassword;
- (NSString*)encrypt:(NSString*)clear;
- (NSString*)decrypt:(NSString*)crypto;
- (BOOL)validatePassword:(NSString*)clearPassword; // Returns YES if OK
- (BOOL)quickCheckOldPassword:(NSString*)clearPassword;
- (BOOL)quickCheckOldPassword:(NSString*)clearPassword fromFile:(NSString*)backupPasswordPath;
+ (BOOL)pinSet;
+ (void)pinRemove;
- (void)pinSetNew:(NSString*)newPin;
- (BOOL)validatePin:(NSString*)clearPin;
+ (void)presentPinOrPasswordEntryModal:(BOOL)hideKeyboard;

@end
