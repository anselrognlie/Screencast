//
//  EWCServiceRegistrationBridge.m
//  Screencast
//
//  Created by Ansel Rognlie on 2018/02/09.
//  Copyright © 2018 Ansel Rognlie. All rights reserved.
//

#import "EWCServiceRegistrationBridge.h"

#import "EWCServiceRegistryRegisterRequest.h"
#import "EWCServiceRegistration.h"

@implementation EWCServiceRegistrationBridge

+ (EWCServiceRegistration *)registrationWithRequest:(EWCServiceRegistryRegisterRequest *)request {
    return [EWCServiceRegistration registrationWithServiceId:request.serviceId
                                                 addressIpv4:request.addressIpv4
                                                        port:request.port
                                                providerName:request.providerName];
}

@end
