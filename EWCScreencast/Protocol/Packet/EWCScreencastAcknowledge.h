//
//  EWCScreencastAcknowledge.h
//  EWCScreencast
//
//  Created by Ansel Rognlie on 2018/02/16.
//  Copyright © 2018 Ansel Rognlie. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "EWCScreencastPacket.h"

@class EWCScreencastProtocol;

@interface EWCScreencastAcknowledge : NSObject<EWCScreencastPacket>

+ (void)registerPacket:(EWCScreencastProtocol *)protocol;
+ (void)unregisterPacket:(EWCScreencastProtocol *)protocol;

+ (instancetype)packetWithBlock:(uint16_t)blockId;

- (instancetype)initWithBlock:(uint16_t)blockId;

@property uint16_t block;

- (NSData *)getData;

@end
