//
//  EWCServiceRegistryClientHandler.h
//  Screencast
//
//  Created by Ansel Rognlie on 2018/02/11.
//  Copyright © 2018 Ansel Rognlie. All rights reserved.
//

#import <Foundation/Foundation.h>

@class EWCAddressIpv4;
@class EWCServiceRegistryAcknowledge;
@class EWCServiceRegistryLocationResponse;

@protocol EWCServiceRegistryClientDelegate <NSObject>

- (void)receivedRegistrationAcknowledgementPacket:(EWCServiceRegistryAcknowledge *)packet
                                      fromAddress:(EWCAddressIpv4 *)address;

- (void)receivedLocationResponsePacket:(EWCServiceRegistryLocationResponse *)packet
                           fromAddress:(EWCAddressIpv4 *)address;

@end
