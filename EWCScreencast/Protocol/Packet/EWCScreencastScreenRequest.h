//
//  EWCScreencastScreenRequest.h
//  EWCScreencast
//
//  Created by Ansel Rognlie on 2018/02/16.
//  Copyright © 2018 Ansel Rognlie. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "EWCScreencastPacket.h"

@class EWCScreencastProtocol;
@class EWCAddressIpv4;

@interface EWCScreencastScreenRequest : NSObject<EWCScreencastPacket>

+ (void)registerPacket:(EWCScreencastProtocol *)protocol;
+ (void)unregisterPacket:(EWCScreencastProtocol *)protocol;

+ (instancetype)packetWithProviderName:(NSString *)providerName
                            lastScreen:(uint16_t)screenId;

- (instancetype)initWithProviderName:(NSString *)providerName
                          lastScreen:(uint16_t)screenId;

@property NSString *providerName;
@property uint16_t screenId;

- (NSData *)getData;

@end
