//
//  EWCServiceRegistryAcknowledge.h
//  Screencast
//
//  Created by Ansel Rognlie on 2018/02/07.
//  Copyright © 2018 Ansel Rognlie. All rights reserved.
//

#import "EWCServiceRegistryPacket.h"

@class EWCServiceRegistryProtocol;

@interface EWCServiceRegistryAcknowledge : NSObject<EWCServiceRegistryPacket>

+ (void)registerPacket:(EWCServiceRegistryProtocol *)protocol;
+ (void)unregisterPacket:(EWCServiceRegistryProtocol *)protocol;

+ (instancetype)packetWithTimeout:(NSTimeInterval)timeout;

- (instancetype)initWithTimeout:(NSTimeInterval)timeout;

@property uint16_t timeout;
@property uint16_t block;

- (NSData *)getData;

@end
