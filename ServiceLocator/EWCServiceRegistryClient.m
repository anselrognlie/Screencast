//
//  EWCServiceRegistryClient.m
//  Screencast
//
//  Created by Ansel Rognlie on 2018/02/08.
//  Copyright © 2018 Ansel Rognlie. All rights reserved.
//

#import "EWCServiceRegistryClient.h"
#import "../Network/EWCUdpChannel+EWCUdpChannelProtected.h"

#import <netinet/in.h>
#import "EWCServiceRegistryProtocol.h"
#import "EWCServiceRegistryRegisterRequest.h"

@interface EWCServiceRegistryClient()
@end

@implementation EWCServiceRegistryClient {
}

- (void)registerService:(NSUUID *)serviceId
           providerName:(NSString *)providerName
                   port:(uint16_t)port {
    // get a register request
    EWCServiceRegistryRegisterRequest *request;
    request = [EWCServiceRegistryRegisterRequest packetWithServiceId:serviceId
                                                        providerName:providerName
                                                                port:port];

    // convert to data
    NSData *data = [request getData];

    // send it
    [self broadcastPacketData:data port:EWCServiceRegistryPort];
}

- (uint16_t) listenerPort {
    // just use a dynamic port
    return 0;
}

- (BOOL)enableBroadcast {
    // service registry client uses broadcast
    return YES;
}

- (void)handlePacketData:(NSData *)data fromAddress:(struct sockaddr_in *)address {
    EWCServiceRegistryProtocol *protocol = EWCServiceRegistryProtocol.protocol;
    [protocol handlePacketData:data fromAddress:address handler:self];
}

- (void)processAcknowledge:(EWCServiceRegistryAcknowledge *)packet {
}

- (void)processRegisterRequest:(EWCServiceRegistryRegisterRequest *)packet {
}

@end
