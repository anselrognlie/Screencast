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

- (void)handlePacketData:(NSData *)data fromAddress:(EWCAddressIpv4 *)address {
    EWCServiceRegistryProtocol *protocol = EWCServiceRegistryProtocol.protocol;
    [protocol handlePacketData:data fromAddress:address handler:self];
}

- (EWCServiceRegistration *)registerRequest:(EWCServiceRegistryRegisterRequest *)request {
    // clean any expired records
    [self cleanupRecords];

    EWCServiceRegistration *reg = nil;
    reg = [self updateOrAddRecordForRequest:request];

    return reg;
}

- (void)unregisterRequest:(EWCServiceRegistryUnregisterRequest *)request {
    // clean any expired records
    [self cleanupRecords];

    [self removeRecordForRequest:request];
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
    EWCRegistrationList *serviceEntry = [self getOrCreateEntryForService:request.serviceId];

    // if current record already exists, just extend timeout
    reg = [self getRegistrationFromEntry:serviceEntry
                                 address:request.address];
    if (reg) {
        reg.whenAdded = [NSDate date];
    } else {
        // otherwise add entry with timeout
        reg = [EWCServiceRegistrationBridge registrationWithRequest:request];
        [serviceEntry addObject:reg];
    }

    return reg;
}

- (EWCRegistrationList *)getOrCreateEntryForService:(NSUUID *)serviceId {
    EWCRegistrationList *records = self.services[serviceId];
    if (records == nil) {
        records = [EWCRegistrationList array];
        self.services[serviceId] = records;
    }

    return records;
}

- (EWCRegistrationList *)getEntryForService:(NSUUID *)serviceId {
    EWCRegistrationList *records = self.services[serviceId];
    return records;
}

- (EWCServiceRegistration *)getRegistrationFromEntry:(EWCRegistrationList *)serviceEntry
                                             address:(EWCAddressIpv4 *)address {
    __block EWCServiceRegistration *reg = nil;
    [serviceEntry enumerateObjectsUsingBlock:^(EWCServiceRegistration * _Nonnull record, NSUInteger idx, BOOL * _Nonnull stop) {
        if ([record.address isEqual:address]) {
            reg = record;
            *stop = YES;
        }
    }];

    return reg;
}

- (void)acknowledgeRegistrationAtTime:(NSDate *)whenAdded
                            toAddress:(EWCAddressIpv4 *)address {
    // calculate the interval
    NSDate *now = [NSDate date];
    NSTimeInterval interval = [now timeIntervalSinceDate:whenAdded];
    interval = self.recordTimeoutSeconds - interval;

    // make an ack packet
    EWCServiceRegistryAcknowledge *ack;
    ack = [EWCServiceRegistryAcknowledge packetWithTimeout:interval];

    // convert to data
    NSData *data = [ack getData];

    // send it back to the requestor
    [self sendPacketData:data toAddress:address];
}

- (void)removeRecordForRequest:(EWCServiceRegistryUnregisterRequest *)request {
    // get any existing entry for the service (creating new if needed)
    EWCRegistrationList *serviceEntry = [self getEntryForService:request.serviceId];

    if (! serviceEntry) { return; }

    // if we can find a record for this, remove it from the list
    EWCServiceRegistration *reg = [self getRegistrationFromEntry:serviceEntry
                                                         address:request.address];
    if (reg) {
        [serviceEntry removeObject:reg];
        NSLog(@"removed record");
    }
}

// Handlers for protocol ////////////////////////////////////////////////

- (void)processAcknowledge:(EWCServiceRegistryAcknowledge *)packet
               fromAddress:(EWCAddressIpv4 *)address {
}

- (void)processRegisterRequest:(EWCServiceRegistryRegisterRequest *)packet
                   fromAddress:(EWCAddressIpv4 *)address {
    in_addr_t addr = packet.address.addressIpv4;
    uint8_t *byte = (uint8_t *)&addr;
    NSLog(@"service %@ at %d.%d.%d.%d:%d (%@)",
          packet.serviceId,
          byte[3], byte[2], byte[1], byte[0],
          packet.address.port,
          packet.providerName);

    EWCServiceRegistration *reg = [self registerRequest:packet];
    addr = reg.address.addressIpv4;
    NSLog(@"request registered:");
    NSLog(@"service %@ at %d.%d.%d.%d:%d (%@) on %@",
          reg.serviceId,
          byte[3], byte[2], byte[1], byte[0],
          reg.address.port,
          reg.providerName,
          reg.whenAdded);

    // send reply to requester
    [self acknowledgeRegistrationAtTime:reg.whenAdded toAddress:address];
}

- (void)processUnregisterRequest:(EWCServiceRegistryUnregisterRequest *)packet
                     fromAddress:(EWCAddressIpv4 *)address {
    in_addr_t addr = packet.address.addressIpv4;
    uint8_t *byte = (uint8_t *)&addr;
    NSLog(@"unregister %@ at %d.%d.%d.%d:%d",
          packet.serviceId,
          byte[3], byte[2], byte[1], byte[0],
          packet.address.port);

    [self unregisterRequest:packet];
}

- (void)processQueryRequest:(EWCServiceRegistryQueryRequest *)packet
                fromAddress:(EWCAddressIpv4 *)address {
    NSLog(@"query request");
}

@end
