//
//  EWCServiceRegistrationBridge.h
//  Screencast
//
//  Created by Ansel Rognlie on 2018/02/09.
//  Copyright © 2018 Ansel Rognlie. All rights reserved.
//

#import <Foundation/Foundation.h>

@class EWCServiceRegistryRegisterRequest;
@class EWCServiceRegistration;

@interface EWCServiceRegistrationBridge : NSObject

+ (EWCServiceRegistration *)registrationWithRequest:(EWCServiceRegistryRegisterRequest *)request;

@end
