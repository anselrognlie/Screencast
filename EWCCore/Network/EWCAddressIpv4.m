//
//  EWCAddressIpv4.m
//  Screencast
//
//  Created by Ansel Rognlie on 2018/02/11.
//  Copyright © 2018 Ansel Rognlie. All rights reserved.
//

#import "EWCAddressIpv4.h"

#import <netinet/in.h>

#define uint32_t_size sizeof(uint32_t)

_Static_assert((sizeof(uint32_t) == sizeof(in_addr_t)), "sizeof(uint32_t) != sizeof(in_addr_t)");

@implementation EWCAddressIpv4

+ (instancetype)addressWithPort:(uint16_t)port {
    return [self addressWithAddressIpv4:0 port:port];
}

+ (instancetype)addressWithAddressIpv4:(uint32_t)addressIpv4 port:(uint16_t)port {
    return [[self alloc] initWithAddressIpv4:addressIpv4 port:port];
}

+ (instancetype)addressWithAddress:(struct sockaddr_in const *)address {
    return [[self alloc] initWithAddress:address];
}

- (instancetype)initWithPort:(uint16_t)port {
    return [self initWithAddressIpv4:0 port:port];
}

- (instancetype)initWithAddressIpv4:(uint32_t)addressIpv4 port:(uint16_t)port {
    self = [super init];

    self.addressIpv4 = addressIpv4;
    self.port = port;

    return self;
}

- (instancetype)initWithAddress:(struct sockaddr_in const *)address {
    return [self initWithAddressIpv4:ntohl(address->sin_addr.s_addr)
                                port:ntohs(address->sin_port)];
}

- (BOOL)isEqual:(id)object {
    if ([object isKindOfClass:[self class]]) {
        EWCAddressIpv4 *other = (EWCAddressIpv4 *)object;
        if (self.addressIpv4 == other.addressIpv4 &&
            self.port == other.port) {
            return YES;
        }
    }

    return NO;
}

- (instancetype)copy {
    return [EWCAddressIpv4 addressWithAddressIpv4:self.addressIpv4 port:self.port];
}

@end
