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
                                  address:(EWCAddressIpv4 *)address
                             providerName:(NSString *)name {
    EWCServiceRegistration *reg = nil;
    reg = [[self alloc] initWithServiceId:serviceId
                                  address:address
                             providerName:name];
    return reg;
}

- (instancetype)init {
    return [self initWithServiceId:nil address:nil providerName:nil];
}

- (instancetype)initWithServiceId:(NSUUID *)serviceId
                          address:(EWCAddressIpv4 *)address
                     providerName:(NSString *)name {
    self = [super init];

    self.serviceId = [serviceId copy];
    self.address = address;
    self.providerName = [name copy];
    self.whenAdded = [NSDate date];

    return self;
}

@end
