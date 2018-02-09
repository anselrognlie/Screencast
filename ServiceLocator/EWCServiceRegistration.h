//
//  EWCServiceRegistration.h
//  Screencast
//
//  Created by Ansel Rognlie on 2018/02/09.
//  Copyright © 2018 Ansel Rognlie. All rights reserved.
//

#import <Foundation/Foundation.h>

#import <netinet/in.h>

@interface EWCServiceRegistration : NSObject

@property NSUUID *serviceId;
@property in_addr_t addressIpv4;
@property uint16_t port;
@property NSString *providerName;
@property NSDate *whenAdded;

+ (instancetype)registrationWithServiceId:(NSUUID *)serviceId
                              addressIpv4:(in_addr_t)address
                                     port:(uint16_t)port
                             providerName:(NSString *)name;

- (instancetype)initWithServiceId:(NSUUID *)serviceId
                      addressIpv4:(in_addr_t)address
                             port:(uint16_t)port
                     providerName:(NSString *)name;

@end
