//
//  EWCScreencastAcknowledge.m
//  EWCScreencast
//
//  Created by Ansel Rognlie on 2018/02/16.
//  Copyright © 2018 Ansel Rognlie. All rights reserved.
//

#import "EWCScreencastAcknowledge.h"

#import "EWCScreencastProtocol.h"
#import "EWCScreencastProtocolHandler.h"
#import "EWCScreencastProtocolOpcode.h"
#import "EWCCore/Network/EWCDataHelper.h"
#import "EWCCore/Network/EWCAddressIpv4.h"

struct EWCRawAcknowledge {
    uint16_t operation;
    uint16_t blockId;
    uint8_t checksum;
};

typedef struct EWCRawAcknowledge EWCRawPacket;

static uint8_t CalculateChecksum(EWCRawPacket const *data);
static BOOL IsRawPacket(NSData * data);
static size_t GetRawPacketSize(void);

static int registrationToken = 0;

@implementation EWCScreencastAcknowledge {
}

+ (void)registerPacket:(EWCScreencastProtocol *)protocol {
    registrationToken = [protocol registerPacketParser:^(NSData *data, EWCAddressIpv4 *address){
        return [EWCScreencastAcknowledge parsePacketData:data fromAddress:address];
    }
                        recognizer:^(NSData *data){
                            return [EWCScreencastAcknowledge isAcknowledge:data];
                        }];
}

+ (void)unregisterPacket:(EWCScreencastProtocol *)protocol {
    [protocol unregisterPacketParser:registrationToken];
}

+ (instancetype)packetWithBlock:(uint16_t)blockId {
    return [[EWCScreencastAcknowledge alloc] initWithBlock:blockId];

}

+ (NSObject<EWCScreencastPacket> *)parsePacketData:(NSData *)data
                                  fromAddress:(EWCAddressIpv4 *)address {
    EWCScreencastAcknowledge *packet = nil;

    // perform trivial check again
    if (! IsRawPacket(data)) { return packet; }

    // unpack the bytes
    // must not return between here and free
    EWCRawPacket *ack = malloc(sizeof(*ack));
    EWC_EXTRACT_BEGIN
    EWC_EXTRACT_DATA(ack->operation, data);
    EWC_EXTRACT_DATA(ack->blockId, data);
    EWC_EXTRACT_DATA(ack->checksum, data);
    EWC_EXTRACT_END

    // fix the byte order where necessary
    EWC_NTOHS(ack->operation);
    EWC_NTOHS(ack->blockId);

    // perform and verify the checksum calculation
    uint8_t checksum = CalculateChecksum(ack);

    if (checksum == ack->checksum) {
        // we have a valid packet, so we need to create a packet instance and populate it
        packet = [EWCScreencastAcknowledge packetWithBlock:ack->blockId];
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
    return [self initWithBlock:0];
}

- (instancetype)initWithBlock:(uint16_t)blockId {
    self = [super init];

    self.block = blockId;

    return self;
}

- (uint16_t) opcode {
    return EWCAcknowledgeOpcode;
}

- (NSData *)getData {
    // fill in raw packet structure with available data
    EWCRawPacket *ack = malloc(sizeof(*ack));

    ack->operation = self.opcode;
    ack->blockId = self.block;
    ack->checksum = CalculateChecksum(ack);

    EWC_HTONS(ack->operation);
    EWC_HTONS(ack->blockId);

    NSMutableData *data = [NSMutableData dataWithCapacity:GetRawPacketSize()];
    EWC_APPEND_DATA(data, ack->operation);
    EWC_APPEND_DATA(data, ack->blockId);
    EWC_APPEND_DATA(data, ack->checksum);

    free(ack);

    return data;
}

- (void)processWithHandler:(NSObject<EWCScreencastProtocolHandler> *)handler
               fromAddress:(EWCAddressIpv4 *)address {
    [handler processAcknowledge:self fromAddress:address];
}

@end

static uint8_t CalculateChecksum(EWCRawPacket const *data) {
    // the request struct must be in host byte order
    uint8_t checksum = 0;

    EWC_UPDATE_CHECKSUM(checksum, data->operation);
    EWC_UPDATE_CHECKSUM(checksum, data->blockId);

    return checksum;
}

static BOOL IsRawPacket(NSData * data) {
//    NSLog(@"is acknowledge?");

    // check length
    if (data.length != GetRawPacketSize()) { return NO; }

    // get the first 2 bytes of the data to see whether this matches
    uint16_t opcode;
    [data getBytes:&opcode length:sizeof(opcode)];
    EWC_NTOHS(opcode);

    if (opcode != EWCAcknowledgeOpcode) { return NO; }

    return YES;
}

static size_t GetRawPacketSize(void) {
    size_t size = 0;

    EWC_UPDATE_SIZE(size, EWCRawPacket, operation);
    EWC_UPDATE_SIZE(size, EWCRawPacket, blockId);
    EWC_UPDATE_SIZE(size, EWCRawPacket, checksum);

    return size;
}
