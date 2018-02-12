//
//  EWCServiceRegistryQueryRequest.m
//  Screencast
//
//  Created by Ansel Rognlie on 2018/02/12.
//  Copyright © 2018 Ansel Rognlie. All rights reserved.
//

#import "EWCServiceRegistryQueryRequest.h"

#import "EWCServiceRegistryProtocol.h"
#import "EWCServiceRegistryProtocolHandler.h"
#import "EWCServiceRegistryProtocolOpcode.h"
#import "EWCDataHelper.h"
#import "../Network/EWCAddressIpv4.h"

struct EWCRawQueryRequest {
    uint16_t operation;
    uint8_t serviceUuid[16];  // 128 bits
    uint8_t checksum;
};

typedef struct EWCRawQueryRequest EWCRawPacket;

static uint8_t CalculateChecksum(EWCRawPacket const *data);
static BOOL IsRawPacket(NSData * data);
static size_t GetRawPacketSize(void);

@interface EWCServiceRegistryQueryRequest()
@end

@implementation EWCServiceRegistryQueryRequest {
}

+ (instancetype)packetWithServiceId:(NSUUID *)serviceId {
    return [[EWCServiceRegistryQueryRequest alloc]
            initWithServiceId:serviceId];
}

+ (NSObject<EWCServiceRegistryPacket> *)parsePacketData:(NSData *)data
                                            fromAddress:(EWCAddressIpv4 *)address {
    EWCServiceRegistryQueryRequest *packet = nil;

    // perform trivial check again
    if (! IsRawPacket(data)) { return packet; }

    // unpack the bytes
    // must not return between here and free
    EWCRawPacket *request = malloc(sizeof(*request));
    EWC_EXTRACT_BEGIN
    EWC_EXTRACT_DATA(request->operation, data);
    EWC_EXTRACT_DATA(request->serviceUuid, data);
    EWC_EXTRACT_DATA(request->checksum, data);
    EWC_EXTRACT_END

    // fix the byte order where necessary
    request->operation = ntohs(request->operation);

    // perform and verify the checksum calculation
    uint8_t checksum = CalculateChecksum(request);

    if (checksum == request->checksum) {
        NSUUID *serviceId =[[NSUUID alloc] initWithUUIDBytes:request->serviceUuid];

        packet = [EWCServiceRegistryQueryRequest packetWithServiceId:serviceId];
    }

    // free the work memory
    free(request);

    // return result (might be nil)
    return packet;
}

+ (BOOL)isQueryRequest:(NSData *)data {
    return IsRawPacket(data);
}

- (instancetype)init {
    return [[EWCServiceRegistryQueryRequest alloc]
            initWithServiceId:nil];
}

- (instancetype)initWithServiceId:(NSUUID *)serviceId {
    self = [super init];

    self.serviceId = [serviceId copy];

    return self;
}

- (uint16_t)opcode {
    return EWCQueryRequestOpcode;
}

- (NSData *)getData {
    // fill in raw packet structure with available data
    EWCRawPacket *request = malloc(sizeof(*request));

    request->operation = self.opcode;
    [self.serviceId getUUIDBytes:request->serviceUuid];
    request->checksum = CalculateChecksum(request);

    request->operation = htons(request->operation);

    NSMutableData *data = [NSMutableData dataWithCapacity:GetRawPacketSize()];
    EWC_APPEND_DATA(data, request->operation);
    EWC_APPEND_DATA(data, request->serviceUuid);
    EWC_APPEND_DATA(data, request->checksum);

    free(request);

    return data;
}

- (void)processWithHandler:(NSObject<EWCServiceRegistryProtocolHandler> *)handler
               fromAddress:(EWCAddressIpv4 *)address {
    [handler processQueryRequest:self fromAddress:address];
}

@end

static uint8_t CalculateChecksum(EWCRawPacket const *data) {
    // the request struct must be in host byte order
    uint8_t checksum = 0;

    // must calculate field by field do to possibility of padding altering result
    EWC_UPDATE_CHECKSUM(checksum, data->operation);
    EWC_UPDATE_CHECKSUM(checksum, data->serviceUuid);

    return checksum;
}

static BOOL IsRawPacket(NSData * data) {
    // if the opcode field is 1 and the length is correct,
    // then it can only be a register request
    // note that the packet may still be malformed and return an invalid packet

    NSLog(@"is query request?");

    // check length
    if (data.length != GetRawPacketSize()) { return NO; }

    // get the first 2 bytes of the data to see whether this matches
    uint16_t opcode;
    [data getBytes:&opcode length:sizeof(opcode)];
    opcode = ntohs(opcode);

    if (opcode != EWCQueryRequestOpcode) { return NO; }

    return YES;
}

static size_t GetRawPacketSize(void) {
    size_t size = 0;

    EWC_UPDATE_SIZE(size, EWCRawPacket, operation);
    EWC_UPDATE_SIZE(size, EWCRawPacket, serviceUuid);
    EWC_UPDATE_SIZE(size, EWCRawPacket, checksum);

    return size;
}

static int registrationToken = 0;

__attribute__((constructor))
static void EWCServiceRegistryQueryRequest_initialize() {
    EWCServiceRegistryProtocol *protocol = EWCServiceRegistryProtocol.protocol;
    registrationToken = [protocol registerPacketParser:^(NSData *data, EWCAddressIpv4 *address){
        return [EWCServiceRegistryQueryRequest parsePacketData:data fromAddress:address];
    }
                                            recognizer:^(NSData *data){
                                                return [EWCServiceRegistryQueryRequest isQueryRequest:data];
                                            }];
}

__attribute__((destructor))
static void EWCServiceRegistryQueryRequest_destroy() {
    EWCServiceRegistryProtocol *protocol = EWCServiceRegistryProtocol.protocol;
    [protocol unregisterPacketParser:registrationToken];
}

