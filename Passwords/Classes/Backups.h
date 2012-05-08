//
//  Backups.h
//  Passwords
//
//  Created by Chris Hulbert on 1/03/12.
//  Copyright (c) 2012 Splinter Software. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface Backups : NSObject

+ (void)appLaunchBackup;
+ (NSArray*)listBackups;
+ (NSArray*)groupsForBackup:(NSString*)backup;
+ (NSArray*)itemsForBackup:(NSString*)backup;
+ (BOOL)doesHaveSamePassword:(NSString*)backupYmd;
+ (NSString*)backupPath;
+ (void)doRestore:(NSString*)backupYmd;

@end
