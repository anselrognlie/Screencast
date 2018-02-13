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

- (void)unregisterService:(NSUUID *)serviceId
                     port:(uint16_t)port {
    // get a register request
    EWCServiceRegistryUnregisterRequest *request;
    request = [EWCServiceRegistryUnregisterRequest packetWithServiceId:serviceId
                                                                  port:port];

    // convert to data
    NSData *data = [request getData];

    // send it
    [self broadcastPacketData:data port:EWCServiceRegistryPort];
}

- (void)queryService:(NSUUID *)serviceId {
    // get a register request
    EWCServiceRegistryQueryRequest *request;
    request = [EWCServiceRegistryQueryRequest packetWithServiceId:serviceId];

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

- (void)handlePacketData:(NSData *)data fromAddress:(EWCAddressIpv4 *)address {
    EWCServiceRegistryProtocol *protocol = EWCServiceRegistryProtocol.protocol;
    [protocol handlePacketData:data fromAddress:address handler:self];
}

- (void)processAcknowledge:(EWCServiceRegistryAcknowledge *)packet
               fromAddress:(EWCAddressIpv4 *)address {
    NSLog(@"registered. will expire in %d seconds", packet.timeout);

    [self.clientHandler receivedRegistrationAcknowledgementPacket:packet
                                                      fromAddress:address];
}

- (void)processRegisterRequest:(EWCServiceRegistryRegisterRequest *)packet
                   fromAddress:(EWCAddressIpv4 *)address {
}

- (void)processUnregisterRequest:(EWCServiceRegistryUnregisterRequest *)packet
                     fromAddress:(EWCAddressIpv4 *)address {
}

- (void)processQueryRequest:(EWCServiceRegistryQueryRequest *)packet
                fromAddress:(EWCAddressIpv4 *)address {
}

- (void)processLocationResponse:(EWCServiceRegistryLocationResponse *)packet
                    fromAddress:(EWCAddressIpv4 *)address {
    NSLog(@"location response:");
    NSLog(@"    serviceId: %@", packet.serviceId);
    uint32_t addr = packet.address.addressIpv4;
    uint8_t *byte = (uint8_t *)&addr;
    NSLog(@"    at %d.%d.%d.%d:%d (%@)",
          byte[3], byte[2], byte[1], byte[0],
          packet.address.port,
          packet.providerName);

    [self.clientHandler receivedLocationResponsePacket:packet
                                           fromAddress:address];
}

@end
