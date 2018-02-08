//
//  EWCServiceRegistryProtocolHandler.h
//  Screencast
//
//  Created by Ansel Rognlie on 2018/02/07.
//  Copyright © 2018 Ansel Rognlie. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "EWCServiceRegistryRegisterRequest.h"
#import "EWCServiceRegistryAcknowledge.h"

@protocol EWCServiceRegistryProtocolHandler <NSObject>

- (void)processRegisterRequest:(EWCServiceRegistryRegisterRequest *)packet;
- (void)processAcknowledge:(EWCServiceRegistryAcknowledge *)packet;

@end
