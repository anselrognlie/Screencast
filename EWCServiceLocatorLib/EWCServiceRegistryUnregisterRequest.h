//
//  EWCServiceRegistryUnregisterRequest.h
//  Screencast
//
//  Created by Ansel Rognlie on 2018/02/12.
//  Copyright © 2018 Ansel Rognlie. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "EWCServiceRegistryPacket.h"
#import "EWCLib/Network/EWCAddressIpv4.h"

@interface EWCServiceRegistryUnregisterRequest : NSObject<EWCServiceRegistryPacket>

// client use
+ (instancetype)packetWithServiceId:(NSUUID *)serviceId
                               port:(uint16_t)port;

// server use
+ (instancetype)packetWithServiceId:(NSUUID *)serviceId
                            address:(EWCAddressIpv4 *)address;

// client use
- (instancetype)initWithServiceId:(NSUUID *)serviceId
                             port:(uint16_t)port;

// server
- (instancetype)initWithServiceId:(NSUUID *)serviceId
                          address:(EWCAddressIpv4 *)address;

@property NSUUID *serviceId;
@property EWCAddressIpv4 *address;

- (NSData *)getData;

@end
