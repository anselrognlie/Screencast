//
//  EWCServiceRegistryUnregisterRequest.m
//  Screencast
//
//  Created by Ansel Rognlie on 2018/02/12.
//  Copyright © 2018 Ansel Rognlie. All rights reserved.
//

#import "EWCServiceRegistryUnregisterRequest.h"

#import "EWCServiceRegistryProtocol.h"
#import "EWCServiceRegistryProtocolHandler.h"
#import "EWCServiceRegistryProtocolOpcode.h"
#import "EWCDataHelper.h"
#import "EWCCore/Network/EWCAddressIpv4.h"

struct EWCRawUnregisterRequest {
    uint16_t operation;
    uint8_t serviceUuid[16];  // 128 bits
    uint16_t port;
    uint8_t checksum;
};

typedef struct EWCRawUnregisterRequest EWCRawPacket;

static uint8_t CalculateChecksum(EWCRawPacket const *data);
static BOOL IsRawPacket(NSData * data);
static size_t GetRawPacketSize(void);

@interface EWCServiceRegistryUnregisterRequest()
@end

static int registrationToken = 0;

@implementation EWCServiceRegistryUnregisterRequest {
}

+ (void)registerPacket:(EWCServiceRegistryProtocol *)protocol {
    registrationToken = [protocol registerPacketParser:^(NSData *data, EWCAddressIpv4 *address){
        return [EWCServiceRegistryUnregisterRequest parsePacketData:data fromAddress:address];
    }
                                            recognizer:^(NSData *data){
                                                return [EWCServiceRegistryUnregisterRequest isUnregisterRequest:data];
                                            }];
}

+ (void)unregisterPacket:(EWCServiceRegistryProtocol *)protocol {
    [protocol unregisterPacketParser:registrationToken];
}

+ (instancetype)packetWithServiceId:(NSUUID *)serviceId
                               port:(uint16_t)port {
    EWCAddressIpv4 *address = [EWCAddressIpv4 addressWithPort:port];

    return [[EWCServiceRegistryUnregisterRequest alloc]
            initWithServiceId:serviceId
            address:address];
}

+ (instancetype)packetWithServiceId:(NSUUID *)serviceId
                            address:(EWCAddressIpv4 *)address {
    return [[EWCServiceRegistryUnregisterRequest alloc]
            initWithServiceId:serviceId
            address:address];
}

+ (NSObject<EWCServiceRegistryPacket> *)parsePacketData:(NSData *)data
                                            fromAddress:(EWCAddressIpv4 *)address {
    EWCServiceRegistryUnregisterRequest *packet = nil;

    // perform trivial check again
    if (! IsRawPacket(data)) { return packet; }

    // unpack the bytes
    // must not return between here and free
    EWCRawPacket *request = malloc(sizeof(*request));
    EWC_EXTRACT_BEGIN
    EWC_EXTRACT_DATA(request->operation, data);
    EWC_EXTRACT_DATA(request->serviceUuid, data);
    EWC_EXTRACT_DATA(request->port, data);
    EWC_EXTRACT_DATA(request->checksum, data);
    EWC_EXTRACT_END

    // fix the byte order where necessary
    EWC_NTOHS(request->operation);
    EWC_NTOHS(request->port);

    // perform and verify the checksum calculation
    uint8_t checksum = CalculateChecksum(request);

    if (checksum == request->checksum) {
        // we have a valid packet, so we need to create a packet instance and populate it
        EWCAddressIpv4 *serviceAddress = [address copy];
        serviceAddress.port = request->port;

        NSUUID *serviceId =[[NSUUID alloc] initWithUUIDBytes:request->serviceUuid];

        packet = [EWCServiceRegistryUnregisterRequest packetWithServiceId:serviceId
                                                                  address:serviceAddress];
    }

    // free the work memory
    free(request);

    // return result (might be nil)
    return packet;
}

+ (BOOL)isUnregisterRequest:(NSData *)data {
    return IsRawPacket(data);
}

- (instancetype)init {
    return [[EWCServiceRegistryUnregisterRequest alloc]
            initWithServiceId:nil
            port:0];
}

- (instancetype)initWithServiceId:(NSUUID *)serviceId
                             port:(uint16_t)port {
    EWCAddressIpv4 *address = [EWCAddressIpv4 addressWithPort:port];

    return [self initWithServiceId:serviceId
                           address:address];
}

- (instancetype)initWithServiceId:(NSUUID *)serviceId
                          address:(EWCAddressIpv4 *)address {
    self = [super init];

    self.address = address;
    self.serviceId = [serviceId copy];

    return self;
}

- (uint16_t)opcode {
    return EWCUnregisterRequestOpcode;
}

- (NSData *)getData {
    // fill in raw packet structure with available data
    EWCRawPacket *request = malloc(sizeof(*request));

    request->operation = self.opcode;
    [self.serviceId getUUIDBytes:request->serviceUuid];
    request->port = self.address.port;
    request->checksum = CalculateChecksum(request);

    EWC_HTONS(request->operation);
    EWC_HTONS(request->port);

    NSMutableData *data = [NSMutableData dataWithCapacity:GetRawPacketSize()];
    EWC_APPEND_DATA(data, request->operation);
    EWC_APPEND_DATA(data, request->serviceUuid);
    EWC_APPEND_DATA(data, request->port);
    EWC_APPEND_DATA(data, request->checksum);

    free(request);

    return data;
}

- (void)processWithHandler:(NSObject<EWCServiceRegistryProtocolHandler> *)handler
               fromAddress:(EWCAddressIpv4 *)address {
    [handler processUnregisterRequest:self fromAddress:address];
}

@end

static uint8_t CalculateChecksum(EWCRawPacket const *data) {
    // the request struct must be in host byte order
    uint8_t checksum = 0;

    // must calculate field by field do to possibility of padding altering result
    EWC_UPDATE_CHECKSUM(checksum, data->operation);
    EWC_UPDATE_CHECKSUM(checksum, data->serviceUuid);
    EWC_UPDATE_CHECKSUM(checksum, data->port);

    return checksum;
}

static BOOL IsRawPacket(NSData * data) {
    // if the opcode field is 1 and the length is correct,
    // then it can only be a register request
    // note that the packet may still be malformed and return an invalid packet

    NSLog(@"is unregister request?");

    // check length
    if (data.length != GetRawPacketSize()) { return NO; }

    // get the first 2 bytes of the data to see whether this matches
    uint16_t opcode;
    [data getBytes:&opcode length:sizeof(opcode)];
    EWC_NTOHS(opcode);

    if (opcode != EWCUnregisterRequestOpcode) { return NO; }

    return YES;
}

static size_t GetRawPacketSize(void) {
    size_t size = 0;

    EWC_UPDATE_SIZE(size, EWCRawPacket, operation);
    EWC_UPDATE_SIZE(size, EWCRawPacket, serviceUuid);
    EWC_UPDATE_SIZE(size, EWCRawPacket, port);
    EWC_UPDATE_SIZE(size, EWCRawPacket, checksum);

    return size;
}
