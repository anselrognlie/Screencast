//
//  EWCServiceRegistryAcknowledge.h
//  Screencast
//
//  Created by Ansel Rognlie on 2018/02/07.
//  Copyright © 2018 Ansel Rognlie. All rights reserved.
//

#import "EWCServiceRegistryPacket.h"

@interface EWCServiceRegistryAcknowledge : NSObject<EWCServiceRegistryPacket>

@property uint16_t timeout;
@property uint16_t block;

- (NSData *)getData;

@end
