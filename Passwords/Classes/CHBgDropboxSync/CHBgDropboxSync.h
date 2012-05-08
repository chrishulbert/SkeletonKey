//
//  CHBgDropboxSync.h
//  Passwords
//
//  Created by Chris Hulbert on 4/03/12.
//  Copyright (c) 2012 Splinter Software. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "DBRestClient.h"

@interface CHBgDropboxSync : NSObject<DBRestClientDelegate, UIAlertViewDelegate>

+ (void)start;
+ (void)forceStopIfRunning;
+ (void)clearLastSyncData;

@end
