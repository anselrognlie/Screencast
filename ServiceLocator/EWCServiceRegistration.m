//
//  EWCServiceRegistration.m
//  Screencast
//
//  Created by Ansel Rognlie on 2018/02/09.
//  Copyright © 2018 Ansel Rognlie. All rights reserved.
//

#import "EWCServiceRegistration.h"

@implementation EWCServiceRegistration

+ (instancetype)registrationWithServiceId:(NSUUID *)serviceId
                              addressIpv4:(in_addr_t)address
                                     port:(uint16_t)port
                             providerName:(NSString *)name {
    EWCServiceRegistration *reg = nil;
    reg = [[self alloc] initWithServiceId:serviceId
                              addressIpv4:address
                                     port:port
                             providerName:name];
    return reg;
}

- (instancetype)init {
    return [self initWithServiceId:nil addressIpv4:0 port:0 providerName:nil];
}

- (instancetype)initWithServiceId:(NSUUID *)serviceId
                      addressIpv4:(in_addr_t)address
                             port:(uint16_t)port
                     providerName:(NSString *)name {
    self = [super init];

    self.serviceId = [serviceId copy];
    self.addressIpv4 = address;
    self.port = port;
    self.providerName = [name copy];
    self.whenAdded = [NSDate date];

    return self;
}

@end
