//
//  EWCScreencastData.h
//  EWCScreencast
//
//  Created by Ansel Rognlie on 2018/02/16.
//  Copyright © 2018 Ansel Rognlie. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "EWCScreencastPacket.h"

@class EWCScreencastProtocol;
@class EWCAddressIpv4;

@interface EWCScreencastData : NSObject<EWCScreencastPacket>

+ (void)registerPacket:(EWCScreencastProtocol *)protocol;
+ (void)unregisterPacket:(EWCScreencastProtocol *)protocol;

+ (instancetype)packetWithBlock:(uint16_t)blockId
                           data:(NSData *)data;

- (instancetype)initWithBlock:(uint16_t)blockId
                         data:(NSData *)data;

@property uint16_t blockId;
@property NSData *data;

- (NSData *)getData;

@end
