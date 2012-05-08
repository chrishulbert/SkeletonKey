//
//  CHBgDropboxSync.m
//  Passwords
//
//  Created by Chris Hulbert on 4/03/12.
//  Copyright (c) 2012 Splinter Software. All rights reserved.
//
// This uses ARC
// Designed for DropboxSDK version 1.1

#import "CHBgDropboxSync.h"
#import <QuartzCore/QuartzCore.h>
#import "DropboxSDK.h"
#import "ConciseKit.h"
#import "Refresh.h"

#define lastSyncDefaultsKey @"CHBgDropboxSyncLastSyncFiles"

// Privates
@interface CHBgDropboxSync() {
    UILabel* workingLabel;
    DBRestClient* client;
    BOOL anyLocalChanges;
    BOOL newPasswordDownloadedDuringSync; // Skeleton-key-specific (you can remove this)
    BOOL hasDoneFirstMetadataLoad; // Skeleton-key-specific (you can remove this)
    UIAlertView* modalAlert; // Only used if we've gone into modal mode
}
- (NSDictionary*)getLocalStatus;
@end

// Singleton instance
CHBgDropboxSync* bgDropboxSyncInstance=nil;

@implementation CHBgDropboxSync

#pragma mark - Showing and hiding the syncing indicator

- (void)showWorking {
    if (workingLabel) return; // Already visible
    
    UIWindow* w = [[[UIApplication sharedApplication] delegate] window];
    workingLabel = [[UILabel alloc] init];
    workingLabel.textAlignment = UITextAlignmentRight;
    workingLabel.text = @"Syncing... ";
    workingLabel.textColor = [UIColor whiteColor];
    int ht = 30;
    workingLabel.frame = CGRectMake(-120, 431-ht, 120, ht);
    workingLabel.backgroundColor = [UIColor colorWithWhite:0 alpha:0.5];
    workingLabel.layer.cornerRadius = 10;
    
    // Spinner
    UIActivityIndicatorView *s = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhite];
    int gap = (workingLabel.frame.size.height - s.frame.size.height) / 2;
    s.frame = CGRectOffset(s.frame, 10+gap, gap);
    [s startAnimating];
    [workingLabel addSubview:s];
    
    // Swoosh it in
    [w addSubview:workingLabel];
    [UIView animateWithDuration:0.3 animations:^{
        workingLabel.frame = CGRectOffset(workingLabel.frame, 110, 0);
    }];
}

- (void)hideWorking {
    if (!workingLabel) return; // Already hidden
    [UIView animateWithDuration:0.3 animations:^{
        workingLabel.frame = CGRectMake(-workingLabel.frame.size.width, workingLabel.frame.origin.y, workingLabel.frame.size.width, workingLabel.frame.size.height);
    } completion:^(BOOL finished) {
        [workingLabel removeFromSuperview];
        workingLabel = nil;
    }];
}

#pragma mark - For when the syncing goes into modal mode

// This is for eg when we do a password change or nuke-n-sync, or any other reason you need it, 
// we want to be modal until it completes, to stop the user messing around with half-synced data.
- (void)goModal {
    if (modalAlert) return;
    modalAlert = [[UIAlertView alloc] initWithTitle:@"Syncing" message:@"Please wait..." delegate:nil cancelButtonTitle:nil otherButtonTitles:nil];
    [modalAlert show];
}

#pragma mark - Startup

- (void)startup {
    if (client) return; // Already started
    
    [self showWorking];
    
    client = [[DBRestClient alloc] initWithSession:[DBSession sharedSession]];
    client.delegate = self;
    
    // Start getting the remote file list
    [client loadMetadata:@"/"];
}

#pragma mark - For keeping track of the last synced status of a file in the nsuserdefaults

// This 'last sync status' is used to justify deletions - that is all it is used for.
// Some thoughts on this 'last sync status' method of keeping track of deletions:
// What happens if we update the 'last sync' for B after updating A?
// Eg we overwrite the last sync state for B after we update A
// Then we've lost track of whether we should do a deletion, and will start mistakenly doing downloads/uploads
// Maybe only remove the last-sync status for each file one at a time as each file attempts deletion
// And at sync completion, grab and update all of them one more time in case something ever slips through the net

// Did the file exist locally at the end of the last sync?
- (BOOL)lastSyncExists:(NSString*)file {
    return [[[NSUserDefaults standardUserDefaults] arrayForKey:lastSyncDefaultsKey] containsObject:file];
}

// Clear all last sync data on pairing change
- (void)lastSyncClear {
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:lastSyncDefaultsKey];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

// Do a full scan of the files and stores them all in the defaults. Only to be used when the sync is totally complete
- (void)lastSyncCompletionRescan {
    [[NSUserDefaults standardUserDefaults] setObject:self.getLocalStatus.allKeys forKey:lastSyncDefaultsKey];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

// Before you attempt to delete a file locally or remotely, call this so that it'll never try to delete that file again.
// Do it before 'attempt delete' instead of 'confirm delete' just in case the delete fails, then we'll fall back to a 'download it again' state for the next sync, which is better than accidentally deleting it erroneously again later
- (void)lastSyncRemove:(NSString*)file {
    NSMutableArray* arr = [NSMutableArray arrayWithArray:[[NSUserDefaults standardUserDefaults] arrayForKey:lastSyncDefaultsKey]];
    [arr removeObject:file];
    [[NSUserDefaults standardUserDefaults] setObject:arr forKey:lastSyncDefaultsKey];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

#pragma mark - Completion / shutdown

// Shutdown code that's common for success/fail/forced shutdowns
- (void)internalCommonShutdown {
    // Autorelease the client using the following two lines, because we don't want it to release *just yet* because it probably called the function that called this, and would crash when the stack pops back to it.
    __autoreleasing DBRestClient* autoreleaseClient = client;
    [autoreleaseClient description];
    
    // Now release the client
    client.delegate = nil;
    client = nil;

    // If we're showing the modal alert, hide it now
    [modalAlert dismissWithClickedButtonIndex:0 animated:YES];
    modalAlert = nil;

    // Free this singleton (put it on the autorelease pool, for safety's sake)
    __autoreleasing CHBgDropboxSync* autoreleaseSingleton = bgDropboxSyncInstance;
    [autoreleaseSingleton description];
    bgDropboxSyncInstance = nil; // Clear the singleton
    
    if (anyLocalChanges) { // Only notify that there were changes at completion, not as we go, so the app doesn't get a half sync state
        [Refresh sendRefresh]; // I'm using another 'refresh' helper that i made here, you may like to do this however you see fit
    }
    if (newPasswordDownloadedDuringSync) {
        [Refresh passwordHasChanged];
    }
}

// For forced shutdowns eg closing the app
- (void)internalShutdownForced {
    [self hideWorking];
    [self internalCommonShutdown];
}

// For clean shutdowns on sync success
- (void)internalShutdownSuccess {
    [self lastSyncCompletionRescan];
    workingLabel.text = @"Done ";
    [self performSelector:@selector(hideWorking) withObject:nil afterDelay:0.5];
    [self internalCommonShutdown];
}

// For failed shutdowns
- (void)internalShutdownFailed {
    workingLabel.text = @"Failed ";
    [self performSelector:@selector(hideWorking) withObject:nil afterDelay:0.5];
    [self internalCommonShutdown];
}

#pragma mark - For when the steps complete

// This re-starts the 'check the metadata' step again, which will then check for any syncing that needs doing, and then kick it off
- (void)stepComplete {
    // Kick off the check the metadata with a little delay so we don't overdo things
    [client performSelector:@selector(loadMetadata:) withObject:@"/" afterDelay:.05];
}

#pragma mark - The async dropbox steps

- (void)startTaskLocalDelete:(NSString*)file {
    NSLog(@"Sync: Deleting local file %@", file);
    [[NSFileManager defaultManager] removeItemAtPath:[$.documentPath stringByAppendingPathComponent:file] error:nil];
    [self stepComplete];
    anyLocalChanges = YES; // So that when we complete, we notify that there were local changes
}

// Upload
- (void)startTaskUpload:(NSString*)file rev:(NSString*)rev {
    NSLog(@"Sync: Uploading file %@, %@", file, rev?@"overwriting":@"new");
    [client uploadFile:file toPath:@"/" withParentRev:rev fromPath:[$.documentPath stringByAppendingPathComponent:file]];
}
- (void)restClient:(DBRestClient *)client uploadedFile:(NSString *)destPath from:(NSString *)srcPath metadata:(DBMetadata *)metadata {
    // Now the file has uploaded, we need to set its 'last modified' date locally to match the date on dropbox.
    // Unfortunately we can't change the dropbox date to match the local date, which would be more appropriate, really.
    NSDictionary* attr = $dict(metadata.lastModifiedDate, NSFileModificationDate);
    [[NSFileManager defaultManager] setAttributes:attr ofItemAtPath:srcPath error:nil];
    [self stepComplete];
}
- (void)restClient:(DBRestClient*)client uploadFileFailedWithError:(NSError*)error {
    [self internalShutdownFailed];
}
// End upload

// Download
- (void)startTaskDownload:(NSString*)file {
    NSLog(@"Sync: Downloading file %@", file);
    [client loadFile:$str(@"/%@", file) intoPath:[$.documentPath stringByAppendingPathComponent:file]];
}
- (void)restClient:(DBRestClient*)client loadedFile:(NSString*)destPath contentType:(NSString*)contentType metadata:(DBMetadata*)metadata {
    // Now the file has downloaded, we need to set its 'last modified' date locally to match the date on dropbox
    NSLog(@"Downloaded >%@<, it's DB date is: %@", destPath, [metadata.lastModifiedDate descriptionWithLocale:[NSLocale currentLocale]]);
    NSDictionary* attr = $dict(metadata.lastModifiedDate, NSFileModificationDate);
    [[NSFileManager defaultManager] setAttributes:attr ofItemAtPath:destPath error:nil];
    [self stepComplete];
    anyLocalChanges = YES; // So that when we complete, we notify that there were local changes
}
- (void)restClient:(DBRestClient *)client loadFileFailedWithError:(NSError *)error {
    [self internalShutdownFailed];
}
// End download

// Remote delete
- (void)startTaskRemoteDelete:(NSString*)file {
    NSLog(@"Sync: Deleting remote file %@", file);
    [client deletePath:$str(@"/%@", file)];
    [self stepComplete];
}
- (void)restClient:(DBRestClient *)client deletedPath:(NSString *)path {
    [self stepComplete];
}
- (void)restClient:(DBRestClient *)client deletePathFailedWithError:(NSError *)error {
    [self internalShutdownFailed];
}
// End remote delete

#pragma mark - Figure out what needs doing after we get the remote metadata

// Get the current status of files and folders as a dict: Path (eg 'abc.txt') => last mod date
- (NSDictionary*)getLocalStatus {
    NSMutableDictionary* localFiles = [NSMutableDictionary dictionary];
    NSString* root = $.documentPath; // Where are we going to sync to
    for (NSString* item in [[NSFileManager defaultManager] contentsOfDirectoryAtPath:root error:nil]) {
        // Skip hidden/system files - you may want to change this if your files start with ., however dropbox errors on many 'ignored' files such as .DS_Store which you'll want to skip
        if ([item hasPrefix:@"."]) continue;

        // Get the full path and attribs
        NSString* itemPath = [root stringByAppendingPathComponent:item];
        NSDictionary* attribs = [[NSFileManager defaultManager] attributesOfItemAtPath:itemPath error:nil];
        BOOL isFile = $eql(attribs.fileType, NSFileTypeRegular);
                
        if (isFile) {
            [localFiles setObject:attribs.fileModificationDate forKey:item];
        }
    }
    return localFiles;
}

// Starts a single sync step, returning YES if nothing needs doing. RemoteFiles is: Path (eg 'abc.txt') => last mod date
- (BOOL)syncStepWithRemoteFiles:(NSDictionary*)remoteFiles andRevs:(NSDictionary*)remoteRevs {
    NSDictionary* localFiles = [self getLocalStatus]; // Get the local filesystem
    [[NSUserDefaults standardUserDefaults] synchronize]; // Make sure the user defaults data is up to date

    NSMutableSet* all = [NSMutableSet set]; // Get a complete list of all files both local and remote
    [all addObjectsFromArray:localFiles.allKeys];
    [all addObjectsFromArray:remoteFiles.allKeys];
    for (NSString* file in all) {
        NSDate* local = [localFiles objectForKey:file];
        NSDate* remote = [remoteFiles objectForKey:file];
        BOOL lastSyncExists = [self lastSyncExists:file];
        if (local && remote) {
            // File is in both places, but are the dates the same?
            double delta = local.timeIntervalSinceReferenceDate - remote.timeIntervalSinceReferenceDate;
            BOOL same = ABS(delta)<2; // If they're within 2 seconds, that's close enough to be the same
            if (!same) {
                // Dates are different, so we need to do something
                // If this was the proper algorithm, we'd check to see if both had changed since the last sync
                // And if so, keep both and rename the older one '*_conflicted'
                if (local.timeIntervalSinceReferenceDate > remote.timeIntervalSinceReferenceDate) {
                    // Local is newer
                    // So send the local file to dropbox, overwriting the existing one with the given 'rev'
                    [self startTaskUpload:file rev:[remoteRevs objectForKey:file]];
                    return NO;
                } else {
                    // Remote is newer
                    // So download the file
                    [self startTaskDownload:file];
                    return NO;
                }
            }
        } else { // Not in both places
            // Say at the end of last sync, it would be in all 3 places: local, remote, and sync
            if (remote && !local) {
                // Dropbox has it, we don't
                // If it was added to db since last sync, it won't be in our sync list, so add it local
                // If it was removed locally since last sync, it'll be in our sync list, so remove from db
                // If never been synced, it won't be in our sync list, so add it locally
                if (lastSyncExists) {
                    // Remove from dropbox
                    [self lastSyncRemove:file]; // Clear the 'last sync' for just this file, so we don't try deleting it again
                    [self startTaskRemoteDelete:file];
                    return NO;
                } else {
                    // Download it
                    [self startTaskDownload:file];
                    return NO;
                }
            }
            if (local && !remote) {
                // We have it, dropbox doesn't
                // If it was added locally since last sync, it won't be in our sync list, so upload it
                // If it was deleted from db since last sync, it will be in our sync list, so delete it locally
                // If never synced, it won't be in our sync list, so upload it
                if (lastSyncExists) {
                    [self lastSyncRemove:file]; // Clear the 'last sync' for just this file, so we don't try deleting it again
                    [self startTaskLocalDelete:file]; // Delete locally
                    return NO;
                } else {
                    // Upload it. 'rev' should be nil here anyway.
                    [self startTaskUpload:file rev:[remoteRevs objectForKey:file]];
                    return NO;
                }
            }
        }
    }
    return YES; // Nothing needs doing
}

#pragma mark - Passwords app-specific stuff. Remove this section if you want to use the syncer in your app!

// Clear out the local files
- (void)nukeLocalFiles {
    NSString* docs = [$ documentPath];
    for (NSString* file in [[NSFileManager defaultManager] contentsOfDirectoryAtPath:docs error:nil]) {
        NSString* path = [docs stringByAppendingPathComponent:file];
        [[NSFileManager defaultManager] removeItemAtPath:path error:nil];
    }
}

- (void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex {
    if (buttonIndex==alertView.firstOtherButtonIndex) {
        // They wish to nuke the local data, since there's a new password on the remote dropbox, and local files will be useless with a new password due to encryption
        [self lastSyncClear]; // Clear the last sync data, so that nothing gets deleted after this, only downloaded.
        [self nukeLocalFiles]; // Delete the local files
        [self goModal]; // Don't allow the user to muck around while we complete the sync
        newPasswordDownloadedDuringSync = YES; // So it'll re-prompt for the new password at the end of the sync
        [client loadMetadata:@"/"]; // Get the metadata again to continue the sync
    } else {
        // Cancel the sync
        [self internalShutdownFailed];
    }
}

- (BOOL)onLoadedMetadataShallIContinue:(DBMetadata*)metadata {    
    // This gets called first thing when we get the metadata from db. First thing to do is check if the password exists in both places and is different. If so, prompt to nuke locally.
    // This handles when you change the password on another device - syncing file by file isn't useful in that case since everything is encrypted by the password-derived key, so the 
    // best way to handle it is to delete local files and then sync.
    
    // Only perform these special checks at the first load of the metadata for the sync (to avoid any delete-loops)
    if (hasDoneFirstMetadataLoad) {
        return YES;
    } else {
        hasDoneFirstMetadataLoad = YES;
    }

    // Check to see if the remote has a password set
    for (DBMetadata* item in metadata.contents) {
        if ([item.path isEqualToString:@"/password.yaml"]) {
            // Does it exist locally?
            NSString* localPasswordsPath = [[$ documentPath] stringByAppendingPathComponent:@"password.yaml"];
            if ([[NSFileManager defaultManager] fileExistsAtPath:localPasswordsPath]) {
                // What is it's date?
                NSDictionary* attribs = [[NSFileManager defaultManager] attributesOfItemAtPath:localPasswordsPath error:nil];
                // Are they > 2s apart?
                double diff = ABS([attribs.fileModificationDate timeIntervalSinceDate:item.lastModifiedDate]);
                if (diff>2) {
                    // Ask them before going ahead with nuking the local data
                    // If they dont want to proceed, cancel the sync till next time
                    [[[UIAlertView alloc] initWithTitle:@"Dropbox Sync" message:@"The master password on Dropbox has changed. To sync, I need to nuke your local data and replace it with what is on Dropbox." delegate:self cancelButtonTitle:@"Cancel" otherButtonTitles:@"Sync", nil] show];
                    return NO;
                }
            } else {
                // Password exists remotely but doesn't exist locally. This is the situation where you open the app, and immediately sync to a pre-existing library before setting a password.
                // If so, nuke the local files without prompting. This avoids the uploading-the-default-groups issue.
                [self lastSyncClear]; // Clear the last sync data, so that nothing gets deleted after this, only downloaded.
                [self nukeLocalFiles]; // Delete the local files - they'll just be the default groups
                [self goModal]; // Don't allow the user to muck around while we complete the sync
                newPasswordDownloadedDuringSync = YES; // So it'll re-prompt for the new password at the end of the sync
            }
        }
    }
    return YES; // Remote doesn't have a password, so nothing special needs to happen with the sync
}

#pragma mark - Callbacks for the load-remote-folder-contents

// Remove the leading slash
- (NSString*)noSlash:(NSString*)file {
    return [file stringByTrimmingCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@"/"]];
}

// Called by dropbox when the metadata for a folder has returned
- (void)restClient:(DBRestClient*)_client loadedMetadata:(DBMetadata*)metadata {
    // Allow the Skeleton-key-app specific stuff to run first. Remove this if you want to use the backgroundsync class in your own app
    if (![self onLoadedMetadataShallIContinue:metadata]) return;
             
    NSMutableDictionary* remoteFiles = [NSMutableDictionary dictionary];
    NSMutableDictionary* remoteFileRevs = [NSMutableDictionary dictionary];
    
    for (DBMetadata* item in metadata.contents) {
        if (item.isDirectory) {
            // Ignore directories for simplicity's sake
        } else {
            [remoteFiles setObject:item.lastModifiedDate forKey:[self noSlash:item.path]];
            [remoteFileRevs setObject:item.rev forKey:[self noSlash:item.path]];
        }
    }
    
    // Now do the comparisons to figure out what needs doing
    BOOL allComplete = [self syncStepWithRemoteFiles:remoteFiles andRevs:remoteFileRevs];
    
    if (allComplete) { // All done - nothing to do!
        [self internalShutdownSuccess];
    }
}
- (void)restClient:(DBRestClient*)client metadataUnchangedAtPath:(NSString*)path {
    [self internalShutdownFailed];
}
- (void)restClient:(DBRestClient*)client loadMetadataFailedWithError:(NSError*)error {
    [self internalShutdownFailed];
}

#pragma mark - Singleton management

+ (CHBgDropboxSync*)i {
    if (!bgDropboxSyncInstance) {
        bgDropboxSyncInstance = [[CHBgDropboxSync alloc] init];
    }
    return bgDropboxSyncInstance;
}

#pragma mark - Publicly accessible stuff you should access from your app delegate

// Call me in your app delegate's applicationDidBecomeActive (eg at startup and become-active) and when you link
// and basically any time you've changed data and want to sync again
+ (void)start {
    if (![[DBSession sharedSession] isLinked]) return; // Not linked, so nothing to do
    [[self i] startup];
}

// Call me from your app delegate when your app closes/goes to the background/unpairs
+ (void)forceStopIfRunning {
    [bgDropboxSyncInstance internalShutdownForced];
}

// Called when they pair or unpair or restore a backup, clears the lastsync status so we dont inadvertantly delete things next time we sync
+ (void)clearLastSyncData {
    [[self i] lastSyncClear]; // Clear the last sync status so 
    // Since last sync status is only used to justify deletes, it is safe to clear (it'll only possibly cause data un-deletion)
}

@end
