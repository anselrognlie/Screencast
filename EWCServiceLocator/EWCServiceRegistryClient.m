//
//  EWCServiceRegistryClient.m
//  Screencast
//
//  Created by Ansel Rognlie on 2018/02/08.
//  Copyright © 2018 Ansel Rognlie. All rights reserved.
//

#import "EWCServiceRegistryClient.h"
#import "EWCCore/Network/EWCUdpChannel+EWCUdpChannelProtected.h"

#import <netinet/in.h>
#import "EWCServiceRegistryProtocol.h"

enum EWCServiceRegistryClientState {
    EWC_SRCS_STARTED,
    EWC_SRCS_AWAIT_REGISTRATION,
    EWC_SRCS_AWAIT_LOCATION,
    EWC_SRCS_DONE,
    EWC_SRCS_TIMEOUT,
};

@interface EWCServiceRegistryClient()
@property NSUUID *queriedServiceId;
@end

@implementation EWCServiceRegistryClient {
    enum EWCServiceRegistryClientState state_;
}

- (void)startOnRunLoop:(NSRunLoop *)runLoop {
    [super startOnRunLoop:runLoop];

    state_ = EWC_SRCS_STARTED;
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

    __weak EWCServiceRegistryClient *me = self;

    state_ = EWC_SRCS_AWAIT_REGISTRATION;

    // allow a brief time frame for an ack, otherwise we'll try again
    [self repeatWithTimeout:1 upTo:3 action:^{
        NSLog(@"registering...");
        [me broadcastPacketData:data port:EWCServiceRegistryPort];
    }];
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

    state_ = EWC_SRCS_AWAIT_LOCATION;
    self.queriedServiceId = serviceId;

    // send it
    __weak EWCServiceRegistryClient *me = self;
    [self repeatWithTimeout:1 upTo:3 action:^{
        NSLog(@"registering...");
        [me broadcastPacketData:data port:EWCServiceRegistryPort];
    }];
}

- (BOOL)enableBroadcast {
    // service registry client uses broadcast
    return YES;
}

- (void)handlePacketData:(NSData *)data fromAddress:(EWCAddressIpv4 *)address {
    EWCServiceRegistryProtocol *protocol = EWCServiceRegistryProtocol.protocol;
    [protocol handlePacketData:data fromAddress:address handler:self];
}

- (void)handleTimeout {
    NSLog(@"timeout");
}

- (void)handleRetriesExceeded {
    NSLog(@"too many retries");

    switch (state_) {
        case EWC_SRCS_AWAIT_LOCATION:
            state_ = EWC_SRCS_TIMEOUT;
            [self.clientHandler noServiceLocated:self.queriedServiceId];
        break;

        default:
            // retries exceeded, but nothing to do
        break;
    }
}

- (void)processAcknowledge:(EWCServiceRegistryAcknowledge *)packet
               fromAddress:(EWCAddressIpv4 *)address {
    NSLog(@"registered. will expire in %d seconds", packet.timeout);

    // prevent further retries
    [self completeAction];

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

    // prevent further retries
    [self completeAction];

    [self.clientHandler receivedLocationResponsePacket:packet
                                           fromAddress:address];
}

@end
