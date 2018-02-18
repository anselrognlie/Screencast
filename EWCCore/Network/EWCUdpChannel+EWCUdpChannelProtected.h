//
//  EWCUdpListener+EWCUdpListenerProtected.h
//  Screencast
//
//  Created by Ansel Rognlie on 2018/02/01.
//  Copyright © 2018 Ansel Rognlie. All rights reserved.
//

#import "EWCUdpChannel.h"

#import "../Network/EWCAddressIpv4.h"

@interface EWCUdpChannel (EWCUdpChannelProtected)

- (void)sendPacketData:(NSData *)data
              toAddress:(EWCAddressIpv4 *)address;
- (void)broadcastPacketData:(NSData *)data
              port:(uint16_t)port;
- (void)setTimeout:(CFTimeInterval)interval;
- (void)repeatWithTimeout:(CFTimeInterval)timeout
                     upTo:(int)times
                   action:(void(^)(void))action;
- (void)completeAction;

@end

