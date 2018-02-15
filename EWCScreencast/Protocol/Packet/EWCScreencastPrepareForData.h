//
//  EWCScreencastPrepareForData.h
//  EWCScreencast
//
//  Created by Ansel Rognlie on 2018/02/16.
//  Copyright © 2018 Ansel Rognlie. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "EWCScreencastPacket.h"

@class EWCScreencastProtocol;

@interface EWCScreencastPrepareForData : NSObject<EWCScreencastPacket>

+ (void)registerPacket:(EWCScreencastProtocol *)protocol;
+ (void)unregisterPacket:(EWCScreencastProtocol *)protocol;

+ (instancetype)packetWithScreenId:(uint16_t)screenId
                         byteCount:(uint32_t)count;

- (instancetype)initWithScreenId:(uint16_t)screenId
                       byteCount:(uint32_t)count;

@property uint16_t screenId;
@property uint32_t byteCount;

- (NSData *)getData;

@end
