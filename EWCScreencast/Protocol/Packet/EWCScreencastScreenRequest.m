//
//  EWCScreencastScreenRequest.m
//  EWCScreencast
//
//  Created by Ansel Rognlie on 2018/02/16.
//  Copyright © 2018 Ansel Rognlie. All rights reserved.
//

#import "EWCScreencastScreenRequest.h"

#import "EWCScreencastProtocol.h"
#import "EWCScreencastProtocolHandler.h"
#import "EWCScreencastProtocolOpcode.h"
#import "EWCCore/Network/EWCDataHelper.h"
#import "EWCCore/Foundation/EWCStringLimiter.h"
#import "EWCCore/Network/EWCAddressIpv4.h"

struct EWCRawScreenRequest {
    uint16_t operation;
    uint16_t screenId;
    uint8_t nameByteCount;  // includes null byte
    uint8_t checksum;
    char providerName[0];
};

typedef struct EWCRawScreenRequest EWCRawPacket;

const static uint8_t EWCMaxNameLength = 128;

static uint8_t CalculateChecksum(EWCRawPacket const *data);
static BOOL IsRawPacket(NSData * data);
static size_t GetMinRawPacketSize(void);

@interface EWCScreencastScreenRequest()
@end

static int registrationToken = 0;

@implementation EWCScreencastScreenRequest {
    char *rawProviderName_;
    int rawProviderNameLength_;  // number of bytes excluding null
}

+ (void)registerPacket:(EWCScreencastProtocol *)protocol {
    registrationToken = [protocol registerPacketParser:^(NSData *data, EWCAddressIpv4 *address){
        return [EWCScreencastScreenRequest parsePacketData:data fromAddress:address];
    }
                                            recognizer:^(NSData *data){
                                                return [EWCScreencastScreenRequest isScreenRequest:data];
                                            }];
}

+ (void)unregisterPacket:(EWCScreencastProtocol *)protocol {
    [protocol unregisterPacketParser:registrationToken];
}

+ (instancetype)packetWithProviderName:(NSString *)providerName
                            lastScreen:(uint16_t)screenId {
    return [[EWCScreencastScreenRequest alloc]
            initWithProviderName:providerName
            lastScreen:screenId];
}

+ (NSObject<EWCScreencastPacket> *)parsePacketData:(NSData *)data
                                            fromAddress:(EWCAddressIpv4 *)address {
    EWCScreencastScreenRequest *packet = nil;

    // perform trivial check again
    if (! IsRawPacket(data)) { return packet; }

    // unpack the bytes
    // must not return between here and free
    EWCRawPacket *request = malloc(sizeof(*request));
    EWC_EXTRACT_BEGIN
    EWC_EXTRACT_DATA(request->operation, data);
    EWC_EXTRACT_DATA(request->screenId, data);
    EWC_EXTRACT_DATA(request->nameByteCount, data);
    EWC_EXTRACT_DATA(request->checksum, data);

    request = realloc(request, sizeof(*request) + request->nameByteCount);
    EWC_EXTRACT_DATA_LEN(request->providerName, data, request->nameByteCount);

    EWC_EXTRACT_END

    // fix the byte order where necessary
    EWC_NTOHS(request->operation);
    EWC_NTOHS(request->screenId);

    // perform and verify the checksum calculation
    uint8_t checksum = CalculateChecksum(request);

    if (checksum == request->checksum) {
        // we have a valid packet
        NSString *providerName = [NSString stringWithUTF8String:request->providerName];

        packet = [EWCScreencastScreenRequest packetWithProviderName:providerName
                                                         lastScreen:request->screenId];
    }

    // free the work memory
    free(request);

    // return result (might be nil)
    return packet;
}

+ (BOOL)isScreenRequest:(NSData *)data {
    return IsRawPacket(data);
}

- (void)dealloc {
    [self releaseProviderName];
}

- (instancetype)init {
    return [[EWCScreencastScreenRequest alloc]
            initWithProviderName:nil
            lastScreen:0];
}

- (instancetype)initWithProviderName:(NSString *)providerName
                          lastScreen:(uint16_t)screenId {
    self = [super init];

    rawProviderName_ = malloc(1);
    *rawProviderName_ = 0;
    rawProviderNameLength_ = 0;

    self.screenId = screenId;
    self.providerName = [providerName copy];

    return self;
}

- (uint16_t)opcode {
    return EWCScreenRequestOpcode;
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
    EWCRawPacket *request = malloc(sizeof(*request) + rawProviderNameLength_);

    request->operation = self.opcode;
    request->screenId = self.screenId;
    request->nameByteCount = rawProviderNameLength_ + 1;  // include null count
    memcpy((char *)request->providerName, rawProviderName_, rawProviderNameLength_ + 1);
    request->checksum = CalculateChecksum(request);

    EWC_HTONS(request->operation);
    EWC_HTONS(request->screenId);

    size_t minCapacity = GetMinRawPacketSize();
    minCapacity += rawProviderNameLength_;

    NSMutableData *data = [NSMutableData dataWithCapacity:minCapacity];
    EWC_APPEND_DATA(data, request->operation);
    EWC_APPEND_DATA(data, request->screenId);
    EWC_APPEND_DATA(data, request->nameByteCount);
    EWC_APPEND_DATA(data, request->checksum);
    EWC_APPEND_DATA_LEN(data, request->providerName, request->nameByteCount);

    free(request);

    return data;
}

- (void)processWithHandler:(NSObject<EWCScreencastProtocolHandler> *)handler
               fromAddress:(EWCAddressIpv4 *)address {
    [handler processScreenRequest:self fromAddress:address];
}

@end

static uint8_t CalculateChecksum(EWCRawPacket const *data) {
    // the request struct must be in host byte order
    uint8_t checksum = 0;

    // must calculate field by field do to possibility of padding altering result
    EWC_UPDATE_CHECKSUM(checksum, data->operation);
    EWC_UPDATE_CHECKSUM(checksum, data->screenId);
    EWC_UPDATE_CHECKSUM(checksum, data->nameByteCount);
    EWC_UPDATE_CHECKSUM_LEN(checksum, data->providerName, data->nameByteCount);

    return checksum;
}

static BOOL IsRawPacket(NSData * data) {
    // if the opcode field is 1 and the length is correct,
    // then it can only be a sreen request
    // note that the packet may still be malformed and return an invalid packet

    NSLog(@"is screen request?");

    // check length
    if (data.length < GetMinRawPacketSize()) { return NO; }

    // get the first 2 bytes of the data to see whether this matches
    uint16_t opcode;
    [data getBytes:&opcode length:sizeof(opcode)];
    EWC_NTOHS(opcode);

    if (opcode != EWCScreenRequestOpcode) { return NO; }

    return YES;
}

static size_t GetMinRawPacketSize(void) {
    size_t size = 0;

    EWC_UPDATE_SIZE(size, EWCRawPacket, operation);
    EWC_UPDATE_SIZE(size, EWCRawPacket, screenId);
    EWC_UPDATE_SIZE(size, EWCRawPacket, nameByteCount);
    EWC_UPDATE_SIZE(size, EWCRawPacket, checksum);

    return size;
}

