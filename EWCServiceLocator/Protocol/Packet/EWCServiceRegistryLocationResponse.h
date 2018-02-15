//
//  EWCServiceRegistryLocationResponse.h
//  Screencast
//
//  Created by Ansel Rognlie on 2018/02/13.
//  Copyright © 2018 Ansel Rognlie. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "EWCServiceRegistryPacket.h"

@class EWCServiceRegistryProtocol;
@class EWCAddressIpv4;

@interface EWCServiceRegistryLocationResponse : NSObject<EWCServiceRegistryPacket>

+ (void)registerPacket:(EWCServiceRegistryProtocol *)protocol;
+ (void)unregisterPacket:(EWCServiceRegistryProtocol *)protocol;

+ (instancetype)packetWithServiceId:(NSUUID *)serviceId
                       providerName:(NSString *)providerName
                            address:(EWCAddressIpv4 *)address;

- (instancetype)initWithServiceId:(NSUUID *)serviceId
                     providerName:(NSString *)providerName
                          address:(EWCAddressIpv4 *)address;

@property NSUUID *serviceId;
@property EWCAddressIpv4 *address;
@property NSString *providerName;

- (NSData *)getData;

@end
