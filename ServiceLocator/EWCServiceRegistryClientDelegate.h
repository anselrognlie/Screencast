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

@protocol EWCServiceRegistryClientDelegate <NSObject>

- (void)receivedRegistrationAcknowledgementPacket:(EWCServiceRegistryAcknowledge *)packet
                                     fromaAddress:(EWCAddressIpv4 *)address;

@end
