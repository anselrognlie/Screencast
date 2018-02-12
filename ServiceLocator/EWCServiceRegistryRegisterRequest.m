//
//  EWCServiceRegistryRegisterRequest.m
//  Screencast
//
//  Created by Ansel Rognlie on 2018/02/06.
//  Copyright © 2018 Ansel Rognlie. All rights reserved.
//

#import "EWCServiceRegistryRegisterRequest.h"

#import "EWCServiceRegistryProtocol.h"
#import "EWCServiceRegistryProtocolHandler.h"
#import "EWCServiceRegistryProtocolOpcode.h"
#import "EWCDataHelper.h"
#import "../Foundation/EWCStringLimiter.h"
#import "../Network/EWCAddressIpv4.h"

struct EWCRawRegisterRequest {
    uint16_t operation;
    uint8_t serviceUuid[16];  // 128 bits
    uint16_t port;
    uint8_t nameByteCount;  // includes null byte
    uint8_t checksum;
    char providerName[0];
};

typedef struct EWCRawRegisterRequest EWCRawPacket;

const static uint8_t EWCMaxNameLength = 128;

static uint8_t CalculateChecksum(EWCRawPacket const *data);
static BOOL IsRawPacket(NSData * data);
static size_t GetMinRawPacketSize(void);

@interface EWCServiceRegistryRegisterRequest()
@end

@implementation EWCServiceRegistryRegisterRequest {
    char *rawProviderName_;
    int rawProviderNameLength_;  // number of bytes excluding null
}

+ (instancetype)packetWithServiceId:(NSUUID *)serviceId
                       providerName:(NSString *)providerName
                               port:(uint16_t)port {
    EWCAddressIpv4 *address = [EWCAddressIpv4 addressWithPort:port];

    return [[EWCServiceRegistryRegisterRequest alloc]
            initWithServiceId:serviceId
            providerName:providerName
            address:address];
}

+ (instancetype)packetWithServiceId:(NSUUID *)serviceId
                       providerName:(NSString *)providerName
                        address:(EWCAddressIpv4 *)address {
    return [[EWCServiceRegistryRegisterRequest alloc]
            initWithServiceId:serviceId
            providerName:providerName
            address:address];
}

+ (NSObject<EWCServiceRegistryPacket> *)parsePacketData:(NSData *)data
                                            fromAddress:(EWCAddressIpv4 *)address {
    EWCServiceRegistryRegisterRequest *packet = nil;

    // perform trivial check again
    if (! IsRawPacket(data)) { return packet; }

    // unpack the bytes
    // must not return between here and free
    struct EWCRawRegisterRequest *request = malloc(sizeof(*request));
    EWC_EXTRACT_BEGIN
    EWC_EXTRACT_DATA(request->operation, data);
    EWC_EXTRACT_DATA(request->serviceUuid, data);
    EWC_EXTRACT_DATA(request->port, data);
    EWC_EXTRACT_DATA(request->nameByteCount, data);
    EWC_EXTRACT_DATA(request->checksum, data);

    request = realloc(request, sizeof(*request) + request->nameByteCount);
    EWC_EXTRACT_DATA_LEN(request->providerName, data, request->nameByteCount);

    EWC_EXTRACT_END

    // fix the byte order where necessary
    request->operation = ntohs(request->operation);
    request->port = ntohs(request->port);

    // perform and verify the checksum calculation
    uint8_t checksum = CalculateChecksum(request);

    if (checksum == request->checksum) {
        // we have a valid packet, so we need to create a packet instance and populate it
        EWCAddressIpv4 *serviceAddress = [address copy];
        serviceAddress.port = request->port;

        NSUUID *serviceId =[[NSUUID alloc] initWithUUIDBytes:request->serviceUuid];

        NSString *providerName = [NSString stringWithUTF8String:request->providerName];

        packet = [EWCServiceRegistryRegisterRequest packetWithServiceId:serviceId
                                                           providerName:providerName
                                                                address:serviceAddress];
    }

    // free the work memory
    free(request);

    // return result (might be nil)
    return packet;
}

+ (BOOL)isRegisterRequest:(NSData *)data {
    return IsRawPacket(data);
}

- (void)dealloc {
    [self releaseProviderName];
}

- (instancetype)init {
    return [[EWCServiceRegistryRegisterRequest alloc]
            initWithServiceId:nil
            providerName:nil
            port:0];
}

- (instancetype)initWithServiceId:(NSUUID *)serviceId
                     providerName:(NSString *)providerName
                             port:(uint16_t)port {
    EWCAddressIpv4 *address = [EWCAddressIpv4 addressWithPort:port];

    return [self initWithServiceId:serviceId
                      providerName:providerName
                           address:address];
}

- (instancetype)initWithServiceId:(NSUUID *)serviceId
                     providerName:(NSString *)providerName
                          address:(EWCAddressIpv4 *)address {
    self = [super init];

    rawProviderName_ = malloc(1);
    *rawProviderName_ = 0;
    rawProviderNameLength_ = 0;

    self.address = address;
    self.serviceId = [serviceId copy];
    self.providerName = [providerName copy];

    return self;
}

- (uint16_t)opcode {
    return EWCRegisterRequestOpcode;
}

- (NSString *)providerName {
    // convert the utf8 string for return
    return [NSString stringWithUTF8String:rawProviderName_];
}

- (void)setProviderName:(NSString *)providerName {
    // convert to UTF8

    // get a substring that will fit in the max storage
    NSString *trimmed = [EWCStringLimiter cutString:providerName
                                         toFitBytes:EWCMaxNameLength];

    // get required length (excludes NULL byte, so increment to allow room)
    NSUInteger len = [trimmed lengthOfBytesUsingEncoding:NSUTF8StringEncoding];
    ++len;

    [self releaseProviderName];
    rawProviderName_ = malloc(len);
    [providerName getCString:rawProviderName_ maxLength:len encoding:NSUTF8StringEncoding];

    // length should store just count chars, not null
    rawProviderNameLength_ = (uint8_t)len - 1;
}

- (void)releaseProviderName {
    if (rawProviderName_) {
        char *tmp = rawProviderName_;
        rawProviderName_ = NULL;
        rawProviderNameLength_ = 0;

        free(tmp);
    }
}

- (NSData *)getData {
    // fill in raw packet structure with available data
    struct EWCRawRegisterRequest *request = malloc(sizeof(*request) + rawProviderNameLength_);

    request->operation = EWCRegisterRequestOpcode;
    [self.serviceId getUUIDBytes:request->serviceUuid];
    request->port = self.address.port;
    request->nameByteCount = rawProviderNameLength_ + 1;  // include null count
    memcpy((char *)request->providerName, rawProviderName_, rawProviderNameLength_ + 1);
    request->checksum = CalculateChecksum(request);

    request->operation = htons(request->operation);
    request->port = htons(request->port);

    size_t minCapacity = GetMinRawPacketSize();
    minCapacity += rawProviderNameLength_;

    NSMutableData *data = [NSMutableData dataWithCapacity:GetMinRawPacketSize()];
    EWC_APPEND_DATA(data, request->operation);
    EWC_APPEND_DATA(data, request->serviceUuid);
    EWC_APPEND_DATA(data, request->port);
    EWC_APPEND_DATA(data, request->nameByteCount);
    EWC_APPEND_DATA(data, request->checksum);
    EWC_APPEND_DATA_LEN(data, request->providerName, request->nameByteCount);

    free(request);

    return data;
}

- (void)processWithHandler:(NSObject<EWCServiceRegistryProtocolHandler> *)handler
               fromAddress:(EWCAddressIpv4 *)address {
    [handler processRegisterRequest:self fromAddress:address];
}

@end

static uint8_t CalculateChecksum(EWCRawPacket const *data) {
    // the request struct must be in host byte order
    uint8_t checksum = 0;

    // must calculate field by field do to possibility of padding altering result
    EWC_UPDATE_CHECKSUM(checksum, data->operation);
    EWC_UPDATE_CHECKSUM(checksum, data->serviceUuid);
    EWC_UPDATE_CHECKSUM(checksum, data->port);
    EWC_UPDATE_CHECKSUM(checksum, data->nameByteCount);
    EWC_UPDATE_CHECKSUM_LEN(checksum, data->providerName, data->nameByteCount);

    return checksum;
}

static BOOL IsRawPacket(NSData * data) {
    // if the opcode field is 1 and the length is correct,
    // then it can only be a register request
    // note that the packet may still be malformed and return an invalid packet

    NSLog(@"is register request?");

    // check length
    if (data.length < GetMinRawPacketSize()) { return NO; }

    // get the first 2 bytes of the data to see whether this matches
    uint16_t opcode;
    [data getBytes:&opcode length:sizeof(opcode)];
    opcode = ntohs(opcode);

    if (opcode != EWCRegisterRequestOpcode) { return NO; }

    return YES;
}

static size_t GetMinRawPacketSize(void) {
    size_t size = 0;

    EWC_UPDATE_SIZE(size, EWCRawPacket, operation);
    EWC_UPDATE_SIZE(size, EWCRawPacket, serviceUuid);
    EWC_UPDATE_SIZE(size, EWCRawPacket, port);
    EWC_UPDATE_SIZE(size, EWCRawPacket, nameByteCount);
    EWC_UPDATE_SIZE(size, EWCRawPacket, checksum);

    return size;
}

static int registrationToken = 0;

__attribute__((constructor))
static void EWCServiceRegistryRegisterRequest_initialize() {
    EWCServiceRegistryProtocol *protocol = EWCServiceRegistryProtocol.protocol;
    registrationToken = [protocol registerPacketParser:^(NSData *data, EWCAddressIpv4 *address){
        return [EWCServiceRegistryRegisterRequest parsePacketData:data fromAddress:address];
    }
                                            recognizer:^(NSData *data){
                                                return [EWCServiceRegistryRegisterRequest isRegisterRequest:data];
                                            }];
}

__attribute__((destructor))
static void EWCServiceRegistryRegisterRequest_destroy() {
    EWCServiceRegistryProtocol *protocol = EWCServiceRegistryProtocol.protocol;
    [protocol unregisterPacketParser:registrationToken];
}

