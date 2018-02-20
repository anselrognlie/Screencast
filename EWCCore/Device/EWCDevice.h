//
//  EWCDevice.h
//  EWCCore
//
//  Created by Ansel Rognlie on 2018/02/19.
//  Copyright © 2018 Ansel Rognlie. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface EWCDevice : NSObject

+ (void)scheduleNameLookupThen:(void(^)(NSString *machineName))continuation;

@end
