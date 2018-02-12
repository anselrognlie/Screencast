//
//  EWCServiceRegistryQueryRequest.h
//  Screencast
//
//  Created by Ansel Rognlie on 2018/02/12.
//  Copyright © 2018 Ansel Rognlie. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "EWCServiceRegistryPacket.h"
#import "../Network/EWCAddressIpv4.h"

@interface EWCServiceRegistryQueryRequest : NSObject<EWCServiceRegistryPacket>

// client use
+ (instancetype)packetWithServiceId:(NSUUID *)serviceId;

// client use
- (instancetype)initWithServiceId:(NSUUID *)serviceId;

@property NSUUID *serviceId;

- (NSData *)getData;

@end
