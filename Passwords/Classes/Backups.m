//
//  Backups.m
//  Passwords
//
//  Created by Chris Hulbert on 1/03/12.
//  Copyright (c) 2012 Splinter Software. All rights reserved.
//

#import "Backups.h"
#import "ConciseKit.h"
#import "MyYaml.h"
#import "NSData+CommonCrypto.h"
#import "Password.h"

@implementation Backups

// Converts a date to yyyy-mm-dd
+ (NSString*)strForDate:(NSDate*)date {
    int comps = NSYearCalendarUnit | NSMonthCalendarUnit | NSDayCalendarUnit;
    NSDateComponents* c = [[NSCalendar currentCalendar] components:comps fromDate:date];
    return $str(@"%04d-%02d-%02d", c.year, c.month, c.day);    
}

// Get the backup path
+ (NSString*)backupPath {
    NSString* libPath = [NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSUserDomainMask, YES) objectAtIndex:0];
    return [libPath stringByAppendingPathComponent:@"Backups"];
}

// Called on app launch. Makes a backup for today if one doesn't already exist. Also deletes old backups.
+ (void)appLaunchBackup {    
    // Find and create the backups folder if necessary
    NSString* backPath = [self backupPath];
    [[NSFileManager defaultManager] createDirectoryAtPath:backPath withIntermediateDirectories:YES attributes:nil error:nil];

    // Figure out today's path
    NSString* nowPath = [backPath stringByAppendingPathComponent:[self strForDate:[NSDate date]]];
    
    // Make a backup if necessary
    if ([Password passwordHasBeenSet]) { // Only make a backup if there's anything worth backing up!
        if ([[NSFileManager defaultManager] fileExistsAtPath:nowPath]) {
            NSLog(@"Backup for today exists, so not backing up");
        } else {
            NSLog(@"Backup for today doesn't exist, so creating and backing up");
            [[NSFileManager defaultManager] copyItemAtPath:[$ documentPath] toPath:nowPath error:nil];
            // Now set the date on it, so it gets the date/time of backup rather than when the source folder was last changed
            NSDictionary* attribs = $dict([NSDate date], NSFileCreationDate, [NSDate date], NSFileModificationDate);
            [[NSFileManager defaultManager] setAttributes:attribs ofItemAtPath:nowPath error:nil];
        }
    }
    
    // Clean up old ones
    NSString* cutoff = [self strForDate:[NSDate dateWithTimeIntervalSinceNow:-32*24*60*60]];
    for (NSString* item in [[NSFileManager defaultManager] contentsOfDirectoryAtPath:backPath error:nil]) {
        if (item.length == cutoff.length && [item compare:cutoff]<0) {
            NSLog(@"Removing old backup %@", item);
            NSString* itemPath = [backPath stringByAppendingPathComponent:item];
            [[NSFileManager defaultManager] removeItemAtPath:itemPath error:nil];
        }
    }
}

// Get the sorted list of backups as an array of [name,date]
+ (NSArray*)listBackups {
    NSMutableArray* arr = [NSMutableArray array];
    NSString* backPath = [self backupPath];
    NSArray* unsorted = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:backPath error:nil];
    NSArray* sorted = [unsorted sortedArrayUsingDescriptors:[NSArray arrayWithObject:[NSSortDescriptor sortDescriptorWithKey:@"self" ascending:NO]]]; // Newest first
    for (NSString* item in sorted) {
        if (item.length==10 && [item rangeOfString:@"-"].length) {
            NSString* itemPath = [backPath stringByAppendingPathComponent:item];
            NSDictionary* attribs = [[NSFileManager defaultManager] attributesOfItemAtPath:itemPath error:nil];
            NSDate* modDate = attribs.fileModificationDate;
            if (item && modDate) {
                [arr addObject:$arr(item,modDate)];
            }
        }
    }
    return arr;
}

// Returns a sorted list of the groups in this backup
+ (NSArray*)groupsForBackup:(NSString*)backup {
    NSString* path = [[self backupPath] stringByAppendingPathComponent:backup];
    NSMutableArray* arr = [NSMutableArray array];
    for (NSString* file in [[NSFileManager defaultManager] contentsOfDirectoryAtPath:path error:nil]) {
        NSString* filePath = [path stringByAppendingPathComponent:file];
        if ([file hasPrefix:@"group_"] && [file hasSuffix:@".yaml"]) {
            NSDictionary *dict = [filePath readPathAsYaml];
            NSString* name = [dict $for:@"name"];
            if (name) {
                [arr addObject:name];
            }
        }
    }
    [arr sortUsingDescriptors:[NSArray arrayWithObject:[NSSortDescriptor sortDescriptorWithKey:@"self" ascending:YES]]];
    return arr;
}

// Returns a sorted list of the items in this backup
+ (NSArray*)itemsForBackup:(NSString*)backup {
    NSString* path = [[self backupPath] stringByAppendingPathComponent:backup];
    NSMutableArray* arr = [NSMutableArray array];
    for (NSString* file in [[NSFileManager defaultManager] contentsOfDirectoryAtPath:path error:nil]) {
        NSString* filePath = [path stringByAppendingPathComponent:file];
        if ([file hasPrefix:@"item_"] && [file hasSuffix:@".yaml"]) {
            NSDictionary *dict = [filePath readPathAsYaml];
            NSString* name = [dict $for:@"name"];
            if (name) {
                [arr addObject:name];
            }
        }
    }
    [arr sortUsingDescriptors:[NSArray arrayWithObject:[NSSortDescriptor sortDescriptorWithKey:@"self" ascending:YES]]];
    return arr;
}

// YES if the given backup has the same password to what is current
+ (BOOL)doesHaveSamePassword:(NSString*)backupYmd {
    NSString* backupPasswordPath = [[[self backupPath] stringByAppendingPathComponent:backupYmd] stringByAppendingPathComponent:@"password.yaml"];
    NSString* currentPasswordPath = [[$ documentPath] stringByAppendingPathComponent:@"password.yaml"];
    NSData* backupHash = [[NSData dataWithContentsOfFile:backupPasswordPath] SHA1Hash];
    NSData* currentHash = [[NSData dataWithContentsOfFile:currentPasswordPath] SHA1Hash];
    return [currentHash isEqualToData:backupHash];
}

// Do the primitive restore (dont take care of dropbox stuff) - clear the documents, and copy the files in
+ (void)doRestore:(NSString*)backupYmd {
    // Clear out the docs
    NSString* docs = [$ documentPath];
    for (NSString* file in [[NSFileManager defaultManager] contentsOfDirectoryAtPath:docs error:nil]) {
        NSString* path = [docs stringByAppendingPathComponent:file];
        [[NSFileManager defaultManager] removeItemAtPath:path error:nil];
    }
    
    // Restore
    NSString* backPath = [[self backupPath] stringByAppendingPathComponent:backupYmd];
    for (NSString* file in [[NSFileManager defaultManager] contentsOfDirectoryAtPath:backPath error:nil]) {
        NSString* fileInBackupPath = [backPath stringByAppendingPathComponent:file];
        NSString* fileInDocsPath = [docs stringByAppendingPathComponent:file];
        [[NSFileManager defaultManager] copyItemAtPath:fileInBackupPath toPath:fileInDocsPath error:nil];
    }
}

@end
