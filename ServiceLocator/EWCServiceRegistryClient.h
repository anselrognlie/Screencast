//
//  EWCServiceRegistryClient.h
//  Screencast
//
//  Created by Ansel Rognlie on 2018/02/08.
//  Copyright © 2018 Ansel Rognlie. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "../Network/EWCUdpChannel.h"
#import "EWCServiceRegistryProtocolHandler.h"

@interface EWCServiceRegistryClient : EWCUdpChannel <EWCServiceRegistryProtocolHandler>

- (void)registerService:(NSUUID *)serviceId
           providerName:(NSString *)providerName
                   port:(uint16_t)port;

@end
