//
//  EWCServiceRegistryProtocol.m
//  Screencast
//
//  Created by Ansel Rognlie on 2018/02/06.
//  Copyright © 2018 Ansel Rognlie. All rights reserved.
//

#import "EWCServiceRegistryProtocol.h"

#import "../Container/EWCPair.h"
#import "EWCServiceRegistryProtocolHandler.h"

typedef EWCPair<EWCServiceRegistryParser, EWCServiceRegistryRecognizer> EWCRegistryPair;

@interface EWCServiceRegistryProtocol()
@property NSMutableDictionary<NSNumber *, EWCRegistryPair *> *protocolHandlers;
@end

@implementation EWCServiceRegistryProtocol {
}

static EWCServiceRegistryProtocol *singleton = nil;
static int registeredProtocols = 0;

+ (EWCServiceRegistryProtocol *)protocol {
    if (! singleton) {
        singleton = [[EWCServiceRegistryProtocol alloc] initPrivate];
    }
    return singleton;
}

- (instancetype)init {
    return nil;
}

- (instancetype)initPrivate {
    self = [super init];

    self.protocolHandlers = [NSMutableDictionary<NSNumber *, EWCRegistryPair *> dictionary];

    return self;
}

- (void)handlePacketData:(NSData *)data
             fromAddress:(EWCAddressIpv4 *)address
                 handler:(NSObject<EWCServiceRegistryProtocolHandler> *)handler {
    // extract the packet
    NSObject<EWCServiceRegistryPacket> *packet = [self parsePacketData:data fromAddress:address];

    NSLog(@"packet result: %@", packet);
    NSLog(@"packet has type: %d", packet.opcode);

    // inform the packet to process using the handler
    [packet processWithHandler:handler fromAddress:address];
}

- (NSObject<EWCServiceRegistryPacket> *)parsePacketData:(NSData *)data
                                            fromAddress:(EWCAddressIpv4 *)address {
    __block NSObject<EWCServiceRegistryPacket> *packet = nil;

    // for each registered handler, check whether the data matches, then try to parse
    [self.protocolHandlers enumerateKeysAndObjectsUsingBlock:^(NSNumber * _Nonnull token,
                                                               EWCRegistryPair * _Nonnull pair,
                                                               BOOL * _Nonnull stop) {
        if (pair.second(data)) {
            packet = pair.first(data, address);
            *stop = YES;
        }
    }];

    return packet;
}

- (int)registerPacketParser:(EWCServiceRegistryParser)parser
                 recognizer:(EWCServiceRegistryRecognizer)recognizer {
    int token = registeredProtocols++;

    NSNumber *key = [NSNumber numberWithInt:token];
    EWCRegistryPair *pair = [EWCPair<EWCServiceRegistryParser, EWCServiceRegistryRecognizer> pairWithFirst:parser second:recognizer];

    self.protocolHandlers[key] = pair;

    return token;
}

- (void)unregisterPacketParser:(int)token {

    NSNumber *key = [NSNumber numberWithInt:token];

    [self.protocolHandlers removeObjectForKey:key];
}

@end
