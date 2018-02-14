//
//  ServiceRegistry.h
//  Screencast
//
//  Created by Ansel Rognlie on 2018/01/29.
//  Copyright © 2018 Ansel Rognlie. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "EWCLib/Network/EWCUdpChannel.h"
#import "EWCServiceRegistryProtocolHandler.h"

@interface EWCServiceRegistry : EWCUdpChannel <EWCServiceRegistryProtocolHandler>

@end
