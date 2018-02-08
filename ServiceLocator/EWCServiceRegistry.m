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
#import "EWCServiceRegistryProtocol.h"

@interface EWCServiceRegistry()
@end

@implementation EWCServiceRegistry {
}

- (uint16_t) listenerPort {
    return EWCServiceRegistryPort;
}

- (BOOL)enableBroadcast {
    return NO;
}

- (void)handlePacketData:(NSData *)data fromAddress:(struct sockaddr_in *)address {
    EWCServiceRegistryProtocol *protocol = EWCServiceRegistryProtocol.protocol;
    [protocol handlePacketData:data fromAddress:address handler:self];
}

// delete this override
- (void)start {
    [super start];

    struct sockaddr_in boundAddr;
    socklen_t socklen = sizeof(boundAddr);
    [self getBoundAddress:(struct sockaddr *)&boundAddr length:&socklen];
    NSLog(@"bound port: %d", ntohs(boundAddr.sin_port));
}

- (void)processAcknowledge:(EWCServiceRegistryAcknowledge *)packet {
}

- (void)processRegisterRequest:(EWCServiceRegistryRegisterRequest *)packet {
    in_addr_t addr = packet.addressIpv4;
    uint8_t *byte = (uint8_t *)&addr;
    NSLog(@"service %@ at %d.%d.%d.%d:%d (%@)",
          packet.serviceId,
          byte[3], byte[2], byte[1], byte[0],
          packet.port,
          packet.providerName);
}

@end
