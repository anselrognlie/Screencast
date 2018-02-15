//
//  EWCServiceRegistryAcknowledge.m
//  Screencast
//
//  Created by Ansel Rognlie on 2018/02/07.
//  Copyright © 2018 Ansel Rognlie. All rights reserved.
//

#import "EWCServiceRegistryAcknowledge.h"

#import <netinet/in.h>
#import "EWCServiceRegistryProtocol.h"
#import "EWCServiceRegistryProtocolHandler.h"
#import "EWCServiceRegistryProtocolOpcode.h"
#import "EWCDataHelper.h"
#import "EWCCore/Network/EWCAddressIpv4.h"

struct EWCRawAcknowledge {
    uint16_t operation;
    uint16_t blockOrTimeout;
    uint8_t checksum;
};

typedef struct EWCRawAcknowledge EWCRawPacket;

static uint8_t CalculateChecksum(EWCRawPacket const *data);
static BOOL IsRawPacket(NSData * data);
static size_t GetRawPacketSize(void);

static int registrationToken = 0;

@implementation EWCServiceRegistryAcknowledge {
    uint16_t blockOrTimeout_;
}

+ (void)registerPacket:(EWCServiceRegistryProtocol *)protocol {
    registrationToken = [protocol registerPacketParser:^(NSData *data, EWCAddressIpv4 *address){
        return [EWCServiceRegistryAcknowledge parsePacketData:data fromAddress:address];
    }
                        recognizer:^(NSData *data){
                            return [EWCServiceRegistryAcknowledge isAcknowledge:data];
                        }];
}

+ (void)unregisterPacket:(EWCServiceRegistryProtocol *)protocol {
    [protocol unregisterPacketParser:registrationToken];
}

+ (instancetype)packetWithTimeout:(NSTimeInterval)timeout {
    return [[EWCServiceRegistryAcknowledge alloc] initWithTimeout:timeout];
}

- (instancetype)initWithTimeout:(NSTimeInterval)timeout {
    self = [super init];

    self.timeout = timeout;

    return self;
}

+ (NSObject<EWCServiceRegistryPacket> *)parsePacketData:(NSData *)data
                                  fromAddress:(EWCAddressIpv4 *)address {
    EWCServiceRegistryAcknowledge *packet = nil;

    // perform trivial check again
    if (! IsRawPacket(data)) { return packet; }

    // unpack the bytes
    // must not return between here and free
    struct EWCRawAcknowledge *ack = malloc(sizeof(*ack));
    EWC_EXTRACT_BEGIN
    EWC_EXTRACT_DATA(ack->operation, data);
    EWC_EXTRACT_DATA(ack->blockOrTimeout, data);
    EWC_EXTRACT_DATA(ack->checksum, data);
    EWC_EXTRACT_END

    // fix the byte order where necessary
    ack->operation = ntohs(ack->operation);
    ack->blockOrTimeout = ntohs(ack->blockOrTimeout);

    // perform and verify the checksum calculation
    uint8_t checksum = CalculateChecksum(ack);

    if (checksum == ack->checksum) {
        // we have a valid packet, so we need to create a packet instance and populate it
        packet = [EWCServiceRegistryAcknowledge new];
        packet.timeout = ack->blockOrTimeout;
    }

    // free the work memory
    free(ack);

    // return result (might be nil)
    return packet;
}

+ (BOOL)isAcknowledge:(NSData *)data {
    return IsRawPacket(data);
}

- (instancetype)init {
    self = [super init];

    blockOrTimeout_ = 0;

    return self;
}

- (uint16_t)block {
    return blockOrTimeout_;
}

- (void)setBlock:(uint16_t)block {
    blockOrTimeout_ = block;
}

- (uint16_t)timeout {
    return blockOrTimeout_;
}

- (void)setTimeout:(uint16_t)timeout {
    blockOrTimeout_ = timeout;
}

- (uint16_t) opcode {
    return EWCAcknowledgeOpcode;
}

- (NSData *)getData {
    // fill in raw packet structure with available data
    struct EWCRawAcknowledge *ack = malloc(sizeof(*ack));

    ack->operation = EWCAcknowledgeOpcode;
    ack->blockOrTimeout = self.block;
    ack->checksum = CalculateChecksum(ack);

    ack->operation = htons(ack->operation);
    ack->blockOrTimeout = htons(ack->blockOrTimeout);

    NSMutableData *data = [NSMutableData dataWithCapacity:GetRawPacketSize()];
    EWC_APPEND_DATA(data, ack->operation);
    EWC_APPEND_DATA(data, ack->blockOrTimeout);
    EWC_APPEND_DATA(data, ack->checksum);

    free(ack);

    return data;
}

- (void)processWithHandler:(NSObject<EWCServiceRegistryProtocolHandler> *)handler
               fromAddress:(EWCAddressIpv4 *)address {
    [handler processAcknowledge:self fromAddress:address];
}

@end

static uint8_t CalculateChecksum(EWCRawPacket const *data) {
    // the request struct must be in host byte order
    uint8_t checksum = 0;

    EWC_UPDATE_CHECKSUM(checksum, data->operation);
    EWC_UPDATE_CHECKSUM(checksum, data->blockOrTimeout);

    return checksum;
}

static BOOL IsRawPacket(NSData * data) {
    // if the opcode field is 1 and the length is correct,
    // then it can only be a register request
    // note that the packet may still be malformed and return an invalid packet

    NSLog(@"is acknowledge?");

    // check length
    if (data.length != GetRawPacketSize()) { return NO; }

    // get the first 2 bytes of the data to see whether this matches
    uint16_t opcode;
    [data getBytes:&opcode length:sizeof(opcode)];
    opcode = ntohs(opcode);

    if (opcode != EWCAcknowledgeOpcode) { return NO; }

    return YES;
}

static size_t GetRawPacketSize(void) {
    size_t size = 0;

    EWC_UPDATE_SIZE(size, EWCRawPacket, operation);
    EWC_UPDATE_SIZE(size, EWCRawPacket, blockOrTimeout);
    EWC_UPDATE_SIZE(size, EWCRawPacket, checksum);

    return size;
}
