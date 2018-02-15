//
//  EWCServiceRegistrationBridge.m
//  Screencast
//
//  Created by Ansel Rognlie on 2018/02/09.
//  Copyright © 2018 Ansel Rognlie. All rights reserved.
//

#import "EWCServiceRegistrationBridge.h"

#import "Packet/EWCServiceRegistryRegisterRequest.h"
#import "EWCServiceRegistration.h"

@implementation EWCServiceRegistrationBridge

+ (EWCServiceRegistration *)registrationWithRequest:(EWCServiceRegistryRegisterRequest *)request {
    return [EWCServiceRegistration registrationWithServiceId:request.serviceId
                                                     address:request.address
                                                providerName:request.providerName];
}

@end
