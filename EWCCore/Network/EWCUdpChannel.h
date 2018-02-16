//
//  EWCUdpListener.h
//  Screencast
//
//  Created by Ansel Rognlie on 2018/01/30.
//  Copyright © 2018 Ansel Rognlie. All rights reserved.
//

#import <Foundation/Foundation.h>

@class EWCAddressIpv4;

@interface EWCUdpChannel : NSObject

- (void)start;
- (void)startOnRunLoop:(NSRunLoop *)runLoop;
- (void)stop;

- (EWCAddressIpv4 *)getBoundAddress;

@end
