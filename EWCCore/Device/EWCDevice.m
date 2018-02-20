//
//  EWCDevice.m
//  EWCCore
//
//  Created by Ansel Rognlie on 2018/02/19.
//  Copyright © 2018 Ansel Rognlie. All rights reserved.
//

#import "EWCDevice.h"

#if TARGET_OS_IOS == 1
#import <UIKit/UIKit.h>
#endif

@implementation EWCDevice

+ (void)scheduleNameLookupThen:(void(^)(NSString *machineName))continuation {
    dispatch_queue_t dq = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);

    dispatch_async(dq, ^{
        NSString *hostName = nil;

#if TARGET_OS_IOS == 1
        UIDevice *host = UIDevice.currentDevice;
        hostName = host.name;
#else
        NSHost *host = [NSHost currentHost];
        hostName = host.localizedName;
#endif

        NSLog(@"got hostname");

        dispatch_async(dispatch_get_main_queue(), ^{
            continuation(hostName);
        });
    });
}

@end
