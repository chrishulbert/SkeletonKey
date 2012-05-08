//
//  Password.m
//  Passwords
//
//  Created by Chris Hulbert on 20/02/12.
//  Copyright (c) 2012 Splinter Software. All rights reserved.
//

#import "Password.h"
#import "SetPassword.h"
#import "JFBCrypt.h"
#import "NSData+CommonCrypto.h"
#import "NSData+Base64.h"
#import "MyYaml.h"
#import "ConciseKit.h"
#import "Refresh.h"
#import <CommonCrypto/CommonKeyDerivation.h>
#import "MyKeyChain.h"
#import "EnterPin.h"
#import "EnterPassword.h"
#import "CHBgDropboxSync.h"

// 5 bcrypt rounds = ~10 hashes/sec on an iphone 4
// Some guy on stackoverflow recommends 16. But that takes 19s on mac, imagine how slow it'd be on a phone! http://stackoverflow.com/questions/6832445/how-can-bcrypt-have-built-in-salts
#define bcryptRounds 5
#define passwordMinLength 5

@interface Password() {
    NSMutableData* key; // The AES key. Important that this be flushed whenever the app loses foreground
}
- (NSString*)decrypt:(NSString*)crypto withSpecificKey:(NSData*)specificKey;
@end

@implementation Password

+ (Password*)i {
    static id instance=nil;
    if (!instance) {
        instance = [[self alloc] init];
    }
    return instance;
}

- (void)nukeKeyInMemory {
    [key resetBytesInRange:NSMakeRange(0, key.length)]; // Zero out the memory used for the key
    key = nil;
}

- (void)appGoingToBackground {
    [self nukeKeyInMemory];
}

// Makes a random 256-bit salt
- (NSData*)generateSalt256 {
    unsigned char salt[32];
    for (int i=0; i<32; i++) {
        salt[i] = (unsigned char)arc4random();
    }
    return [NSData dataWithBytes:salt length:32];
}

// Generate the AES256 key from the password and the key's bcrypt salt
- (NSMutableData*)makeKeyFromPassword:(NSString*)clearPassword salt:(NSData*)keySalt rounds:(int)keyRounds {
    // Open CommonKeyDerivation.h for help
    NSData* myPassData = [clearPassword dataUsingEncoding:NSUTF8StringEncoding];
    unsigned char rawKey[32];
    CCKeyDerivationPBKDF(kCCPBKDF2, myPassData.bytes, myPassData.length,
                         keySalt.bytes, keySalt.length, kCCPRFHmacAlgSHA256, keyRounds, rawKey, 32);
    return [NSMutableData dataWithBytes:rawKey length:32];
}

// Set the password, for internal use by setting the initial one and changing it
- (void)setPasswordInternal:(NSString*)clearPassword {
    // First bcrypt the password for validation purposes
    NSString* validationSalt = [JFBCrypt generateSaltWithNumberOfRounds:bcryptRounds];
    NSString* validationHash = [JFBCrypt hashPassword:clearPassword withSalt:validationSalt];
    
    // Now make a salt for AES purposes (but at this stage, don't bcrypt/sha256 it to make the key)
    NSData* keySalt = [self generateSalt256];
    // Figure out how many rounds to use so that it'll take 100msec
    int keyRounds = CCCalibratePBKDF(kCCPBKDF2, clearPassword.length, keySalt.length, kCCPRFHmacAlgSHA256, 32, 100);
    
    // Now save it
    NSDictionary* yaml = $dict(validationHash, @"password_bcrypt",
                               validationSalt, @"password_salt",
                               keySalt.base64EncodedString, @"PBKDF2_salt",
                               $int(keyRounds), @"PBKDF2_rounds");
    [yaml yamlWriteDocumentsFile:@"password.yaml"];
    
    // Now store the key in memory, as well as the bcrypt password, so we can know if it's the right key
    // Do the same (storing both) with the keychain too if they want to use a pin
    key = [self makeKeyFromPassword:clearPassword salt:keySalt rounds:keyRounds];
}

// Set the initial password (as opposed to changing an already-set password)
- (void)setPassword:(NSString*)clearPassword {
    if ([[self class] passwordHasBeenSet]) {
        [[[UIAlertView alloc] initWithTitle:@"Error" message:@"Cannot set password, as one is already set" delegate:nil cancelButtonTitle:@"Close" otherButtonTitles:nil] show];
    } else {
        [self setPasswordInternal:clearPassword];
    }
}

+ (int)minLength {
    return passwordMinLength;
}

+ (BOOL)passwordHasBeenSet {
    return [[NSFileManager defaultManager] fileExistsAtPath:[[$ documentPath] stringByAppendingPathComponent:@"password.yaml"]];
}

// Returns YES if they have no password and brings up the password setter
// The idea is that, before adding a password etc, you do: if ([Password requirePasswordFrom:self]) return;
+ (BOOL)requirePasswordFrom:(UIViewController*)vc {
    if (![self passwordHasBeenSet]) {
        SetPassword* s = [[SetPassword alloc] initWithNibName:@"SetPassword" bundle:nil];
        UINavigationController* n = [[UINavigationController alloc] initWithRootViewController:s];
        [vc presentModalViewController:n animated:YES];
        return YES;
    }
    return NO;
}

// Used by the password changer and restorer
- (BOOL)quickCheckOldPassword:(NSString*)clearPassword fromFile:(NSString*)backupPasswordPath {
    // Verify it using bcrypt
    NSDictionary* dict = [backupPasswordPath readPathAsYaml];
    if (!dict) return NO;
    NSString* validationSalt = [dict $for:@"password_salt"];
    NSString* validationHash = [dict $for:@"password_bcrypt"];
    if (!validationSalt.length) return NO;
    if (!validationHash.length) return NO;
    NSString* generatedHash = [JFBCrypt hashPassword:clearPassword withSalt:validationSalt];
    return [generatedHash isEqualToString:validationHash];
}

// Used by the password changer. Does a quick check of the old password. YES if ok
- (BOOL)quickCheckOldPassword:(NSString*)clearPassword {
    return [self quickCheckOldPassword:clearPassword fromFile:[[$ documentPath] stringByAppendingPathComponent:@"password.yaml"]];
}

// Changes the password, and re-encrypts everything, nil if ok, error message if bad
- (NSString*)changePasswordFrom:(NSString*)oldPassword to:(NSString*)newPassword {    
    // Drop the PIN
    [[self class] pinRemove];

    // Get the old key
    NSDictionary* dict = [@"password.yaml" readDocumentsFileAsYaml];
    if (!dict) return @"Could not read password information file";
    int keyRounds = [[dict $for:@"PBKDF2_rounds"] intValue];
    if (!keyRounds) return @"Could not find PBKDF2_rounds field";
    NSString* keySaltString = [dict $for:@"PBKDF2_salt"];
    if (!keySaltString.length) return @"Could not find PBKDF2_salt";
    NSData* keySaltData = [NSData dataFromBase64String:keySaltString];
    if (!keySaltData.length) return @"Could not decode salt";
    NSMutableData* oldKey = [self makeKeyFromPassword:oldPassword salt:keySaltData rounds:keyRounds];
    if (!oldKey.length) return @"Could not derive old key";
    
    // Make the new key and new password.yaml
    [self setPasswordInternal:newPassword];
    
    // Now re-encrypt everything
    NSArray* files = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:[$ documentPath] error:nil];
    for (NSString* file in files) {
        if ([file hasPrefix:@"item_"] && [file hasSuffix:@".yaml"]) {
            NSDictionary *dict = [file readDocumentsFileAsYaml];
            // re-crypt the fields
            NSMutableArray *newFields = [NSMutableArray array];
            for (NSDictionary *oldField in [dict $for:@"fields"]) {
                NSMutableDictionary* newField = [NSMutableDictionary dictionaryWithDictionary:oldField];
                NSString* oldCrypt = [oldField $for:@"value"];
                if (oldCrypt.length) { // Was there any value for this field? Some are blank...
                    NSString* clearValue = [self decrypt:oldCrypt withSpecificKey:oldKey];
                    if (clearValue.length) { // Did it decrypt ok?
                        NSString* newCrypt = [self encrypt:clearValue];
                        if (newCrypt.length) { // Did it re-encrypt ok?
                            [newField setObject:newCrypt forKey:@"value"];
                        }
                    }
                }
                [newFields addObject:newField];
            }            
            // Replace the fields and save the yaml
            NSMutableDictionary *newYaml = [NSMutableDictionary dictionaryWithDictionary:dict];
            [newYaml setObject:newFields forKey:@"fields"];

            // Re-crypt the notes
            NSString* oldNotesCrypt = [dict $for:@"notes"];
            if (oldNotesCrypt.length) { // Were there any notes?
                NSString* clear = [self decrypt:oldNotesCrypt withSpecificKey:oldKey];
                if (clear.length) { // If it decrypted ok
                    NSString* newCrypt = [self encrypt:clear];
                    if (newCrypt.length) { // If it re-encrypted ok
                        [newYaml setObject:newCrypt forKey:@"notes"];
                    }
                }
            }
            
            [newYaml yamlWriteDocumentsFile:file];
        }
    }
    
    // Now nuke the old key
    [oldKey resetBytesInRange:NSMakeRange(0, oldKey.length)];
        
    // Let the app know to refresh stuff
    [Refresh sendRefresh];
    return nil;
}

// Returns YES if OK, stores the key in memory
- (BOOL)validatePassword:(NSString*)clearPassword {
    [self nukeKeyInMemory]; // Will it ever be a problem to clear the key first?
    
    // Verify it using bcrypt
    NSDictionary* dict = [@"password.yaml" readDocumentsFileAsYaml];
    if (!dict) return NO;
    NSString* validationSalt = [dict $for:@"password_salt"];
    NSString* validationHash = [dict $for:@"password_bcrypt"];
    if (!validationSalt.length) return NO;
    if (!validationHash.length) return NO;
    NSString* generatedHash = [JFBCrypt hashPassword:clearPassword withSalt:validationSalt];
    if ([generatedHash isEqualToString:validationHash]) {
        // Password is verified
        // Now make the key
        int keyRounds = [[dict $for:@"PBKDF2_rounds"] intValue];
        if (!keyRounds) return NO;
        NSString* keySaltString = [dict $for:@"PBKDF2_salt"];
        if (!keySaltString.length) return NO;
        NSData* keySaltData = [NSData dataFromBase64String:keySaltString];
        if (!keySaltData.length) return NO;
        key = [self makeKeyFromPassword:clearPassword salt:keySaltData rounds:keyRounds];
        if (!key.length) return NO;
        return YES;
    } else {
        return NO;
    }
}

- (NSString*)encrypt:(NSString*)clear {
    if (!key.length) {
        [[[UIAlertView alloc] initWithTitle:@"Error!" message:@"Could not encrypt: key not in memory" delegate:nil cancelButtonTitle:@"Ok" otherButtonTitles:nil] show];
        return nil;
    }
    if (!$safe(clear).length) { // Handle nils, nsnulls, and empty strings
        return nil;
    }
    
    NSData* clearData = [clear dataUsingEncoding:NSUTF8StringEncoding];
    NSError* err=nil;
    NSData* crypto = [clearData AES256EncryptedDataUsingKey:key error:&err];
    if (err) {
        [[[UIAlertView alloc] initWithTitle:@"Encrypt error!" message:err.localizedDescription delegate:nil cancelButtonTitle:@"Ok" otherButtonTitles:nil] show];
    }
    return [crypto base64EncodedString];
}

- (NSString*)decrypt:(NSString*)crypto withSpecificKey:(NSData*)specificKey {
    if (!$safe(crypto).length) { // Handle nils, nsnulls, and empty strings
        return nil;
    }
    
    NSData* cryptoData = [NSData dataFromBase64String:crypto];
    NSError* err=nil;
    NSData* clearData = [cryptoData decryptedAES256DataUsingKey:specificKey error:&err];
    if (err) {
        [[[UIAlertView alloc] initWithTitle:@"Decrypt error!" message:err.localizedDescription delegate:nil cancelButtonTitle:@"Ok" otherButtonTitles:nil] show];
    }
    return [[NSString alloc] initWithData:clearData encoding:NSUTF8StringEncoding]; 
}

- (NSString*)decrypt:(NSString*)crypto {
    if (!key.length) {
        [[[UIAlertView alloc] initWithTitle:@"Error!" message:@"Could not decrypt: key not in memory" delegate:nil cancelButtonTitle:@"Ok" otherButtonTitles:nil] show];
        return nil;
    }
    if (!$safe(crypto).length) { // Handle nils, nsnulls, and empty strings
        return nil;
    }
    
    NSData* cryptoData = [NSData dataFromBase64String:crypto];
    NSError* err=nil;
    NSData* clearData = [cryptoData decryptedAES256DataUsingKey:key error:&err];
    if (err) {
        [[[UIAlertView alloc] initWithTitle:@"Decrypt error!" message:err.localizedDescription delegate:nil cancelButtonTitle:@"Ok" otherButtonTitles:nil] show];
    }
    return [[NSString alloc] initWithData:clearData encoding:NSUTF8StringEncoding]; 
}

#pragma mark - PIN stuff

// Is a valid PIN set?
+ (BOOL)pinSet {
    NSString* pinPasswordBcrypt = [MyKeyChain get:@"passwordBcrypt"];
    if (pinPasswordBcrypt) {
        // Ok we have a pin set, but does it match the current password?
        NSDictionary* dict = [@"password.yaml" readDocumentsFileAsYaml];
        NSString* realPasswordBcrypt = [dict $for:@"password_bcrypt"];
        if ([pinPasswordBcrypt isEqualToString:realPasswordBcrypt]) {
            return YES; // All matches
        } else {
            // Doesn't match, so just erase it
            [self pinRemove];
            return NO;
        }
    } else {
        return NO; // No pin set at all
    }
}

+ (void)pinRemove {
    [MyKeyChain setValue:nil forKey:@"pinBcrypt"];
    [MyKeyChain setValue:nil forKey:@"pinSalt"];
    [MyKeyChain setValue:nil forKey:@"pinKey"];
    [MyKeyChain setValue:nil forKey:@"passwordBcrypt"];
}

- (void)pinSetNew:(NSString*)newPin {
    NSString* validationSalt = [JFBCrypt generateSaltWithNumberOfRounds:bcryptRounds];
    NSString* validationHash = [JFBCrypt hashPassword:newPin withSalt:validationSalt];
    [MyKeyChain setValue:validationHash forKey:@"pinBcrypt"];
    [MyKeyChain setValue:validationSalt forKey:@"pinSalt"];
    [MyKeyChain setValue:[key base64EncodedString] forKey:@"pinKey"];
    
    // Store the password's bcrypt so that we know if the pin key is valid
    NSDictionary* dict = [@"password.yaml" readDocumentsFileAsYaml];
    NSString* passwordBcrypt = [dict $for:@"password_bcrypt"];
    [MyKeyChain setValue:passwordBcrypt forKey:@"passwordBcrypt"];
}

// Returns YES if OK, stores the key in memory
- (BOOL)validatePin:(NSString*)clearPin {
    if (![Password pinSet]) return NO; // No PIN set
    
    [self nukeKeyInMemory]; // Will it ever be a problem to clear the key first?
    
    // Verify it using bcrypt
    NSString* validationSalt = [MyKeyChain get:@"pinSalt"];
    NSString* validationHash = [MyKeyChain get:@"pinBcrypt"];
    if (!validationSalt.length) return NO;
    if (!validationHash.length) return NO;
    NSString* generatedHash = [JFBCrypt hashPassword:clearPin withSalt:validationSalt];
    if ([generatedHash isEqualToString:validationHash]) {
        // Password is verified
        NSString* base64Key = [MyKeyChain get:@"pinKey"];
        NSData* decodedkey = [NSData dataFromBase64String:base64Key];
        key = [NSMutableData dataWithData:decodedkey];
        if (!key.length) return NO;
        return YES;
    } else {
        return NO;
    }
}

#pragma mark - Opening the modals for pin/password entry

+ (void)presentPinOrPasswordEntryModal:(BOOL)hideKeyboard {
    if ([self pinSet]) {
        EnterPin* p = [[EnterPin alloc] initWithNibName:@"EnterPin" bundle:nil];
        p.hideKeyboard = hideKeyboard;
        UINavigationController* n = [[UINavigationController alloc] initWithRootViewController:p];
        [[[[[UIApplication sharedApplication] delegate] window] rootViewController] presentModalViewController:n animated:NO];
    } else {
        EnterPassword* p = [[EnterPassword alloc] initWithNibName:@"EnterPassword" bundle:nil];
        p.hideKeyboard = hideKeyboard;
        UINavigationController* n = [[UINavigationController alloc] initWithRootViewController:p];
        [[[[[UIApplication sharedApplication] delegate] window] rootViewController] presentModalViewController:n animated:NO];
    }
}

@end
