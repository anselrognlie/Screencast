//
//  EWCBufferedPacket.m
//  Screencast
//
//  Created by Ansel Rognlie on 2018/02/02.
//  Copyright © 2018 Ansel Rognlie. All rights reserved.
//

#import "EWCBufferedPacket.h"

#import "../CoreFoundation/EWCCFTypeRef.h"

@interface EWCBufferedPacket()
@property (nonatomic) CFDataRef data;
@property (nonatomic) CFDataRef address;
@end

@implementation EWCBufferedPacket

+ (instancetype)packetWithData:(CFDataRef)data address:(CFDataRef)address {
    EWCBufferedPacket *packet = [[EWCBufferedPacket alloc] initWithData:data address:address];
    return packet;
}

- (instancetype)initWithData:(CFDataRef)data address:(CFDataRef)address {
    self = [super init];
    
    _data = nil;
    _address = nil;
    
    self.data = data;
    self.address = address;
    
    return self;
}

- (void)dealloc {
    self.data = nil;
    self.address = nil;
}

- (void)setData:(CFDataRef)value {
    EWCSwapCFTypeRef(&_data, &value);
}

- (void)setAddress:(CFDataRef)value {
    EWCSwapCFTypeRef(&_address, &value);
}

@end

