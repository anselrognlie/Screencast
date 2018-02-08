//
//  EWCServiceRegistryPacket.h
//  Screencast
//
//  Created by Ansel Rognlie on 2018/02/06.
//  Copyright © 2018 Ansel Rognlie. All rights reserved.
//

#import <Foundation/Foundation.h>

// forward decl
@protocol EWCServiceRegistryProtocolHandler;

@protocol EWCServiceRegistryPacket<NSObject>

@property (readonly) uint16_t opcode;
- (void)processWithHandler:(NSObject<EWCServiceRegistryProtocolHandler> *)handler;

@end
