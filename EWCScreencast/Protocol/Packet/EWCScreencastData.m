//
//  EWCScreencastData.m
//  EWCScreencast
//
//  Created by Ansel Rognlie on 2018/02/16.
//  Copyright © 2018 Ansel Rognlie. All rights reserved.
//

#import "EWCScreencastData.h"

#import "EWCScreencastProtocol.h"
#import "EWCScreencastProtocolHandler.h"
#import "EWCScreencastProtocolOpcode.h"
#import "EWCCore/Network/EWCDataHelper.h"
#import "EWCCore/Foundation/EWCStringLimiter.h"
#import "EWCCore/Network/EWCAddressIpv4.h"

struct EWCRawData {
    uint16_t operation;
    uint16_t blockId;
    uint16_t dataByteCount;
    uint8_t checksum;
    uint8_t data[0];
};

typedef struct EWCRawData EWCRawPacket;

const static uint16_t EWCMaxDataLength = 400;

static uint8_t CalculateChecksum(EWCRawPacket const *data);
static BOOL IsRawPacket(NSData * data);
static size_t GetMinRawPacketSize(void);

@interface EWCScreencastData()
@property NSData *data;
@end

static int registrationToken = 0;

@implementation EWCScreencastData {
}

+ (NSUInteger)maxDataLength {
    return EWCMaxDataLength;
}

+ (void)registerPacket:(EWCScreencastProtocol *)protocol {
    registrationToken = [protocol registerPacketParser:^(NSData *data, EWCAddressIpv4 *address){
        return [EWCScreencastData parsePacketData:data fromAddress:address];
    }
                                            recognizer:^(NSData *data){
                                                return [EWCScreencastData isData:data];
                                            }];
}

+ (void)unregisterPacket:(EWCScreencastProtocol *)protocol {
    [protocol unregisterPacketParser:registrationToken];
}

+ (instancetype)packetWithBlock:(uint16_t)blockId
                           data:(NSData *)data {
    return [[EWCScreencastData alloc]
            initWithBlock:blockId
            data:data];
}

+ (NSObject<EWCScreencastPacket> *)parsePacketData:(NSData *)data
                                            fromAddress:(EWCAddressIpv4 *)address {
    EWCScreencastData *packet = nil;

    // perform trivial check again
    if (! IsRawPacket(data)) { return packet; }

    // unpack the bytes
    // must not return between here and free
    EWCRawPacket *request = malloc(sizeof(*request));
    EWC_EXTRACT_BEGIN
    EWC_EXTRACT_DATA(request->operation, data);
    EWC_EXTRACT_DATA(request->blockId, data);
    EWC_EXTRACT_DATA(request->dataByteCount, data);
    EWC_EXTRACT_DATA(request->checksum, data);

    EWC_NTOHS(request->dataByteCount);  // flip the byte order before we grab the bytes
    request = realloc(request, sizeof(*request) + request->dataByteCount);
    EWC_EXTRACT_DATA_LEN(request->data, data, request->dataByteCount);

    EWC_EXTRACT_END

    // fix the byte order where necessary
    EWC_NTOHS(request->operation);
    EWC_NTOHS(request->blockId);

    // perform and verify the checksum calculation
    uint8_t checksum = CalculateChecksum(request);

    if (checksum == request->checksum) {
        // we have a valid packet, so we need to create a packet instance and populate it
        NSData *bytes = [NSData dataWithBytes:request->data
                                       length:request->dataByteCount];

        packet = [EWCScreencastData packetWithBlock:request->blockId
                                               data:bytes];
    }

    // free the work memory
    free(request);

    // return result (might be nil)
    return packet;
}

+ (BOOL)isData:(NSData *)data {
    return IsRawPacket(data);
}

- (instancetype)init {
    return [[EWCScreencastData alloc]
            initWithBlock:0
            data:nil];
}

- (instancetype)initWithBlock:(uint16_t)blockId
                         data:(NSData *)data {
    self = [super init];

    self.blockId = blockId;
    self.data = [data copy];

    if (data) {
        if (data.length > EWCMaxDataLength) {
            self.data = nil;
            NSLog(@"supplied data exceeds max length (%lu, %lu)",
                  (unsigned long)data.length,
                  (unsigned long)EWCMaxDataLength);
        }
    }

    return self;
}

- (uint16_t)opcode {
    return EWCDataOpcode;
}

- (NSData *)getData {
    // fill in raw packet structure with available data
    NSUInteger dataLength = self.data.length;
    EWCRawPacket *request = malloc(sizeof(*request) + dataLength);

    request->operation = self.opcode;
    request->blockId = self.blockId;
    request->dataByteCount = dataLength;
    memcpy((char *)request->data, self.data.bytes, dataLength);
    request->checksum = CalculateChecksum(request);

    EWC_HTONS(request->operation);
    EWC_HTONS(request->blockId);
    EWC_HTONS(request->dataByteCount);

    size_t minCapacity = GetMinRawPacketSize();
    minCapacity += dataLength;

    NSMutableData *data = [NSMutableData dataWithCapacity:minCapacity];
    EWC_APPEND_DATA(data, request->operation);
    EWC_APPEND_DATA(data, request->blockId);
    EWC_APPEND_DATA(data, request->dataByteCount);
    EWC_APPEND_DATA(data, request->checksum);
    EWC_APPEND_DATA_LEN(data, request->data, dataLength);

    free(request);

    return data;
}

- (void)processWithHandler:(NSObject<EWCScreencastProtocolHandler> *)handler
               fromAddress:(EWCAddressIpv4 *)address {
    [handler processData:self fromAddress:address];
}

@end

static uint8_t CalculateChecksum(EWCRawPacket const *data) {
    // the request struct must be in host byte order
    uint8_t checksum = 0;

    // must calculate field by field do to possibility of padding altering result
    EWC_UPDATE_CHECKSUM(checksum, data->operation);
    EWC_UPDATE_CHECKSUM(checksum, data->blockId);
    EWC_UPDATE_CHECKSUM(checksum, data->dataByteCount);
    EWC_UPDATE_CHECKSUM_LEN(checksum, data->data, data->dataByteCount);

    return checksum;
}

static BOOL IsRawPacket(NSData * data) {
//    NSLog(@"is data?");

    // check length
    if (data.length < GetMinRawPacketSize()) { return NO; }

    // get the first 2 bytes of the data to see whether this matches
    uint16_t opcode;
    [data getBytes:&opcode length:sizeof(opcode)];
    EWC_NTOHS(opcode);

    if (opcode != EWCDataOpcode) { return NO; }

    return YES;
}

static size_t GetMinRawPacketSize(void) {
    size_t size = 0;

    EWC_UPDATE_SIZE(size, EWCRawPacket, operation);
    EWC_UPDATE_SIZE(size, EWCRawPacket, blockId);
    EWC_UPDATE_SIZE(size, EWCRawPacket, dataByteCount);
    EWC_UPDATE_SIZE(size, EWCRawPacket, checksum);

    return size;
}

