//
//  EWCScreencastProtocol.m
//  EWCScreencat
//
//  Created by Ansel Rognlie on 2018/02/15.
//  Copyright © 2018 Ansel Rognlie. All rights reserved.
//

#import "EWCScreencastProtocol.h"

#import "EWCCore/Container/EWCPair.h"
#import "EWCScreencastProtocolHandler.h"
#import "EWCScreencastPacket.h"
#import "EWCScreencastScreenRequest.h"
#import "EWCScreencastPrepareForData.h"
#import "EWCScreencastAcknowledge.h"
#import "EWCScreencastData.h"

static const char PROTOCOL_SERVICEID_STRING[] = "892BA8F1-1E59-469C-8FB1-C0F1E4E926D6";

typedef EWCPair<EWCScreencastParser, EWCScreencastRecognizer> EWCRegistryPair;

@interface EWCScreencastProtocol()
@property NSMutableDictionary<NSNumber *, EWCRegistryPair *> *protocolHandlers;
@property NSUUID *serviceId;

@end

@implementation EWCScreencastProtocol {
}

static EWCScreencastProtocol *singleton = nil;
static int registeredProtocols = 0;

+ (EWCScreencastProtocol *)protocol {
    if (! singleton) {
        singleton = [[EWCScreencastProtocol alloc] initPrivate];
        [EWCScreencastScreenRequest registerPacket:singleton];
        [EWCScreencastPrepareForData registerPacket:singleton];
        [EWCScreencastAcknowledge registerPacket:singleton];
        [EWCScreencastData registerPacket:singleton];
    }
    return singleton;
}

- (instancetype)init {
    return nil;
}

- (instancetype)initPrivate {
    self = [super init];

    self.protocolHandlers = [NSMutableDictionary<NSNumber *, EWCRegistryPair *> dictionary];
    self.serviceId = [[NSUUID alloc] initWithUUIDString:[NSString stringWithUTF8String:PROTOCOL_SERVICEID_STRING]];

    return self;
}

- (void)handlePacketData:(NSData *)data
             fromAddress:(EWCAddressIpv4 *)address
                 handler:(NSObject<EWCScreencastProtocolHandler> *)handler {
    // extract the packet
    NSObject<EWCScreencastPacket> *packet = [self parsePacketData:data fromAddress:address];

    NSLog(@"packet result: %@", packet);
    NSLog(@"packet has type: %d", packet.opcode);

    // inform the packet to process using the handler
    [packet processWithHandler:handler fromAddress:address];
}

- (NSObject<EWCScreencastPacket> *)parsePacketData:(NSData *)data
                                            fromAddress:(EWCAddressIpv4 *)address {
    __block NSObject<EWCScreencastPacket> *packet = nil;

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

- (int)registerPacketParser:(EWCScreencastParser)parser
                 recognizer:(EWCScreencastRecognizer)recognizer {
    int token = registeredProtocols++;

    NSNumber *key = [NSNumber numberWithInt:token];
    EWCRegistryPair *pair = [EWCPair<EWCScreencastParser, EWCScreencastRecognizer> pairWithFirst:parser second:recognizer];

    self.protocolHandlers[key] = pair;

    return token;
}

- (void)unregisterPacketParser:(int)token {

    NSNumber *key = [NSNumber numberWithInt:token];

    [self.protocolHandlers removeObjectForKey:key];
}

@end
