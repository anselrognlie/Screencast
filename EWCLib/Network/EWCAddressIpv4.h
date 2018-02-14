//
//  EWCAddressIpv4.h
//  Screencast
//
//  Created by Ansel Rognlie on 2018/02/11.
//  Copyright © 2018 Ansel Rognlie. All rights reserved.
//

#import <Foundation/Foundation.h>

#import <netinet/in.h>

@interface EWCAddressIpv4 : NSObject

// properties are read and written in host byte order
@property uint32_t addressIpv4;  // this is equivalent to in_addr_t
@property uint16_t port;

+ (instancetype)addressWithPort:(uint16_t)port;
+ (instancetype)addressWithAddressIpv4:(uint32_t)addressIpv4 port:(uint16_t)port;
// assumes the address is provided in network byte order
+ (instancetype)addressWithAddress:(struct sockaddr_in const *)address;

- (instancetype)initWithPort:(uint16_t)port;
- (instancetype)initWithAddressIpv4:(uint32_t)addressIpv4 port:(uint16_t)port;
// assumes the address is provided in network byte order
- (instancetype)initWithAddress:(struct sockaddr_in const *)address;

- (BOOL)isEqual:(id)object;

- (instancetype)copy;

@end
