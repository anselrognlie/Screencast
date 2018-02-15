//
//  EWCScreencastPrepareForData.m
//  EWCScreencast
//
//  Created by Ansel Rognlie on 2018/02/16.
//  Copyright © 2018 Ansel Rognlie. All rights reserved.
//

#import "EWCScreencastPrepareForData.h"

#import "EWCScreencastProtocol.h"
#import "EWCScreencastProtocolHandler.h"
#import "EWCScreencastProtocolOpcode.h"
#import "EWCCore/Network/EWCDataHelper.h"
#import "EWCCore/Network/EWCAddressIpv4.h"

struct EWCRawPrepareForData {
    uint16_t operation;
    uint16_t screenId;
    uint32_t byteCount;
    uint8_t checksum;
};

typedef struct EWCRawPrepareForData EWCRawPacket;

static uint8_t CalculateChecksum(EWCRawPacket const *data);
static BOOL IsRawPacket(NSData * data);
static size_t GetRawPacketSize(void);

@interface EWCScreencastPrepareForData()
@end

static int registrationToken = 0;

@implementation EWCScreencastPrepareForData {
}

+ (void)registerPacket:(EWCScreencastProtocol *)protocol {
    registrationToken = [protocol registerPacketParser:^(NSData *data, EWCAddressIpv4 *address){
        return [EWCScreencastPrepareForData parsePacketData:data fromAddress:address];
    }
                                            recognizer:^(NSData *data){
                                                return [EWCScreencastPrepareForData isPrepareForData:data];
                                            }];
}

+ (void)unregisterPacket:(EWCScreencastProtocol *)protocol {
    [protocol unregisterPacketParser:registrationToken];
}

+ (instancetype)packetWithScreenId:(uint16_t)screenId
                         byteCount:(uint32_t)count {
    return [[EWCScreencastPrepareForData alloc]
            initWithScreenId:screenId byteCount:count];
}

+ (NSObject<EWCScreencastPacket> *)parsePacketData:(NSData *)data
                                       fromAddress:(EWCAddressIpv4 *)address {
    EWCScreencastPrepareForData *packet = nil;

    // perform trivial check again
    if (! IsRawPacket(data)) { return packet; }

    // unpack the bytes
    // must not return between here and free
    EWCRawPacket *request = malloc(sizeof(*request));
    EWC_EXTRACT_BEGIN
    EWC_EXTRACT_DATA(request->operation, data);
    EWC_EXTRACT_DATA(request->screenId, data);
    EWC_EXTRACT_DATA(request->byteCount, data);
    EWC_EXTRACT_DATA(request->checksum, data);
    EWC_EXTRACT_END

    // fix the byte order where necessary
    EWC_NTOHS(request->operation);
    EWC_NTOHS(request->screenId);
    EWC_NTOHL(request->byteCount);

    // perform and verify the checksum calculation
    uint8_t checksum = CalculateChecksum(request);

    if (checksum == request->checksum) {
        // we have a valid packet
        packet = [EWCScreencastPrepareForData packetWithScreenId:request->screenId
                                                       byteCount:request->byteCount];
    }

    // free the work memory
    free(request);

    // return result (might be nil)
    return packet;
}

+ (BOOL)isPrepareForData:(NSData *)data {
    return IsRawPacket(data);
}

- (instancetype)init {
    return [[EWCScreencastPrepareForData alloc]
            initWithScreenId:0
            byteCount:0];
}

- (instancetype)initWithScreenId:(uint16_t)screenId
                       byteCount:(uint32_t)count {
    self = [super init];

    self.screenId = screenId;
    self.byteCount = count;

    return self;
}

- (uint16_t)opcode {
    return EWCPrepareForDataOpcode;
}

- (NSData *)getData {
    // fill in raw packet structure with available data
    EWCRawPacket *request = malloc(sizeof(*request));

    request->operation = self.opcode;
    request->screenId = self.screenId;
    request->byteCount = CalculateChecksum(request);

    EWC_HTONS(request->operation);
    EWC_HTONS(request->screenId);
    EWC_HTONL(request->byteCount);

    NSMutableData *data = [NSMutableData dataWithCapacity:GetRawPacketSize()];
    EWC_APPEND_DATA(data, request->operation);
    EWC_APPEND_DATA(data, request->screenId);
    EWC_APPEND_DATA(data, request->byteCount);
    EWC_APPEND_DATA(data, request->checksum);

    free(request);

    return data;
}

- (void)processWithHandler:(NSObject<EWCScreencastProtocolHandler> *)handler
               fromAddress:(EWCAddressIpv4 *)address {
    [handler processPrepareForData:self fromAddress:address];
}

@end

static uint8_t CalculateChecksum(EWCRawPacket const *data) {
    // the request struct must be in host byte order
    uint8_t checksum = 0;

    // must calculate field by field do to possibility of padding altering result
    EWC_UPDATE_CHECKSUM(checksum, data->operation);
    EWC_UPDATE_CHECKSUM(checksum, data->screenId);
    EWC_UPDATE_CHECKSUM(checksum, data->byteCount);

    return checksum;
}

static BOOL IsRawPacket(NSData * data) {
    NSLog(@"is prepare for data?");

    // check length
    if (data.length != GetRawPacketSize()) { return NO; }

    // get the first 2 bytes of the data to see whether this matches
    uint16_t opcode;
    [data getBytes:&opcode length:sizeof(opcode)];
    EWC_NTOHS(opcode);

    if (opcode != EWCPrepareForDataOpcode) { return NO; }

    return YES;
}

static size_t GetRawPacketSize(void) {
    size_t size = 0;

    EWC_UPDATE_SIZE(size, EWCRawPacket, operation);
    EWC_UPDATE_SIZE(size, EWCRawPacket, screenId);
    EWC_UPDATE_SIZE(size, EWCRawPacket, byteCount);
    EWC_UPDATE_SIZE(size, EWCRawPacket, checksum);

    return size;
}
