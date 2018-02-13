//
//  EWCServiceRegistryProtocolHandler.h
//  Screencast
//
//  Created by Ansel Rognlie on 2018/02/07.
//  Copyright © 2018 Ansel Rognlie. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "../Network/EWCAddressIpv4.h"
#import "EWCServiceRegistryRegisterRequest.h"
#import "EWCServiceRegistryAcknowledge.h"
#import "EWCServiceRegistryUnregisterRequest.h"
#import "EWCServiceRegistryQueryRequest.h"
#import "EWCServiceRegistryLocationResponse.h"

@protocol EWCServiceRegistryProtocolHandler <NSObject>

- (void)processRegisterRequest:(EWCServiceRegistryRegisterRequest *)packet
                   fromAddress:(EWCAddressIpv4 *)address;
- (void)processAcknowledge:(EWCServiceRegistryAcknowledge *)packet
               fromAddress:(EWCAddressIpv4 *)address;
- (void)processUnregisterRequest:(EWCServiceRegistryUnregisterRequest *)packet
                     fromAddress:(EWCAddressIpv4 *)address;
- (void)processQueryRequest:(EWCServiceRegistryQueryRequest *)packet
                fromAddress:(EWCAddressIpv4 *)address;
- (void)processLocationResponse:(EWCServiceRegistryLocationResponse *)packet
                fromAddress:(EWCAddressIpv4 *)address;

@end
