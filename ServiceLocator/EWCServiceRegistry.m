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
#import "EWCServiceRegistration.h"
#import "EWCServiceRegistrationBridge.h"

typedef NSMutableArray<EWCServiceRegistration *> EWCRegistrationList;
typedef NSMutableDictionary<NSUUID *, EWCRegistrationList *> EWCServiceDictionary;

@interface EWCServiceRegistry()
@property EWCServiceDictionary *services;
@property NSTimeInterval recordTimeoutSeconds;
@end

@implementation EWCServiceRegistry {
}

- (instancetype)init {
    self = [super init];

    self.services = [EWCServiceDictionary dictionary];
    self.recordTimeoutSeconds = 600;  // 10m

    return self;
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

- (EWCServiceRegistration *)registerRequest:(EWCServiceRegistryRegisterRequest *)request {
    // clean any expired records
    [self cleanupRecords];

    EWCServiceRegistration *reg = nil;
    reg = [self updateOrAddRecordForRequest:request];

    return reg;
}

- (void)cleanupRecords {
    NSMutableArray<NSUUID *> *emptyServices = [NSMutableArray<NSUUID *> array];
    NSDate *now = [NSDate date];

    // iterate over services and their registries
    [self.services enumerateKeysAndObjectsUsingBlock:^(NSUUID * _Nonnull serviceId, EWCRegistrationList * _Nonnull records, BOOL * _Nonnull serviceStop) {
        NSMutableArray<NSNumber *> *expiredRecords = [NSMutableArray<NSNumber *> array];

        // iterate over records in list
        [records enumerateObjectsUsingBlock:^(EWCServiceRegistration * _Nonnull record, NSUInteger idx, BOOL * _Nonnull recordStop) {
            NSTimeInterval recordAge = [now timeIntervalSinceDate:record.whenAdded];
            if (recordAge > self.recordTimeoutSeconds) {
                // note index of expired records
                [expiredRecords addObject:[NSNumber numberWithUnsignedInteger:idx]];
            }
        }];

        // remove expired records
        for (NSNumber *expiredNumber in [expiredRecords reverseObjectEnumerator]) {
            NSUInteger expiredIndex = [expiredNumber unsignedIntegerValue];
            [records removeObjectAtIndex:expiredIndex];
        }

        // note services with empty records
        if (records.count == 0) {
            [emptyServices addObject:serviceId];
        }
    }];

    // remove empty services
    for (NSUUID *emptyService in emptyServices) {
        [self.services removeObjectForKey:emptyService];
    }
}

- (EWCServiceRegistration *)updateOrAddRecordForRequest:(EWCServiceRegistryRegisterRequest *)request {
    EWCServiceRegistration *reg = nil;

    // get any existing entry for the service (creating new if needed)
    EWCRegistrationList *serviceEntry = [self getEntryForService:request.serviceId];

    // if current record already exists, just extend timeout
    reg = [self getRegistrationFromEntry:serviceEntry
                                 addressIpv4:request.addressIpv4
                                    port:request.port];
    if (reg) {
        reg.whenAdded = [NSDate date];
    } else {
        // otherwise add entry with timeout
        reg = [EWCServiceRegistrationBridge registrationWithRequest:request];
        [serviceEntry addObject:reg];
    }

    return reg;
}

- (EWCRegistrationList *)getEntryForService:(NSUUID *)serviceId {
    EWCRegistrationList *records = self.services[serviceId];
    if (records == nil) {
        records = [EWCRegistrationList array];
        self.services[serviceId] = records;
    }

    return records;
}

- (EWCServiceRegistration *)getRegistrationFromEntry:(EWCRegistrationList *)serviceEntry
                                         addressIpv4:(in_addr_t)address
                                                port:(uint16_t)port {
    __block EWCServiceRegistration *reg = nil;
    [serviceEntry enumerateObjectsUsingBlock:^(EWCServiceRegistration * _Nonnull record, NSUInteger idx, BOOL * _Nonnull stop) {
        if (record.addressIpv4 == address &&
            record.port == port) {
            reg = record;
            *stop = YES;
        }
    }];

    return reg;
}

// Handlers for protocol ////////////////////////////////////////////////

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

    EWCServiceRegistration *reg = [self registerRequest:packet];
    addr = reg.addressIpv4;
    NSLog(@"request registered:");
    NSLog(@"service %@ at %d.%d.%d.%d:%d (%@) on %@",
          reg.serviceId,
          byte[3], byte[2], byte[1], byte[0],
          reg.port,
          reg.providerName,
          reg.whenAdded);

    // send reply to requester
    NSLog(@"MUST REPLY TO REQUESTER");
}

@end
