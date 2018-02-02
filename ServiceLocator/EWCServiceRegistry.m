//
//  ServiceRegistry.m
//  Screencast
//
//  Created by Ansel Rognlie on 2018/01/29.
//  Copyright © 2018 Ansel Rognlie. All rights reserved.
//

#import "EWCServiceRegistry.h"
#import "../Network/EWCUdpChannel+EWCUdpChannelProtected.h"

#import <netinet/in.h>

@interface EWCServiceRegistry()
@end

@implementation EWCServiceRegistry {
}

- (uint16_t) listenerPort {
    return 13887;
}

- (BOOL)enableBroadcast {
    return NO;
}

- (void)handlePacketData:(NSData *)data fromAddress:(struct sockaddr_in *)address {
    // echo back to sender
    [self sendPacketData:data toAddress:address];
}

@end
