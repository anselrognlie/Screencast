//
//  EWCServiceRegistryRegisterRequest.h
//  Screencast
//
//  Created by Ansel Rognlie on 2018/02/06.
//  Copyright © 2018 Ansel Rognlie. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "EWCServiceRegistryPacket.h"
#import <netinet/in.h>

@interface EWCServiceRegistryRegisterRequest : NSObject<EWCServiceRegistryPacket>

// client use
+ (instancetype)packetWithServiceId:(NSUUID *)serviceId
providerName:(NSString *)providerName
port:(uint16_t)port;

// server use
+ (instancetype)packetWithServiceId:(NSUUID *)serviceId
providerName:(NSString *)providerName
addressIpv4:(in_addr_t)addressIpv4
port:(uint16_t)port;

// client use
- (instancetype)initWithServiceId:(NSUUID *)serviceId
providerName:(NSString *)providerName
port:(uint16_t)port;

// server
- (instancetype)initWithServiceId:(NSUUID *)serviceId
providerName:(NSString *)providerName
addressIpv4:(in_addr_t)addressIpv4
port:(uint16_t)port;

@property NSUUID *serviceId;
@property uint16_t port;
@property in_addr_t addressIpv4;
@property NSString *providerName;

- (NSData *)getData;

@end
