//
//  EWCServiceRegistration.h
//  Screencast
//
//  Created by Ansel Rognlie on 2018/02/09.
//  Copyright © 2018 Ansel Rognlie. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "../Network/EWCAddressIpv4.h"

@interface EWCServiceRegistration : NSObject

@property NSUUID *serviceId;
@property EWCAddressIpv4 *address;
@property NSString *providerName;
@property NSDate *whenAdded;

+ (instancetype)registrationWithServiceId:(NSUUID *)serviceId
                                  address:(EWCAddressIpv4 *)address
                             providerName:(NSString *)name;

- (instancetype)initWithServiceId:(NSUUID *)serviceId
                          address:(EWCAddressIpv4 *)address
                     providerName:(NSString *)name;

@end
