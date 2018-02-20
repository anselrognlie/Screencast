//
//  EWCScreencastDataChannel.h
//  EWCScreencast
//
//  Created by Ansel Rognlie on 2018/02/17.
//  Copyright © 2018 Ansel Rognlie. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "EWCCore/Network/EWCUdpChannel.h"
#import "EWCScreencastProtocolHandler.h"

@protocol EWCScreencastDataChannelDelegate;
@class EWCAddressIpv4;

@interface EWCScreencastDataChannel : EWCUdpChannel <EWCScreencastProtocolHandler>

@property (class, readonly) uint16_t count;

+ (instancetype)channelToAddress:(EWCAddressIpv4 *)address
                          screen:(uint16_t)screenId
                            data:(NSData *)data
                         handler:(NSObject<EWCScreencastDataChannelDelegate> *)handler;

- (instancetype)initToAddress:(EWCAddressIpv4 *)address
                       screen:(uint16_t)screenId
                         data:(NSData *)data
                      handler:(NSObject<EWCScreencastDataChannelDelegate> *)handler;

@property (readonly) uint16_t screenId;
@property (readonly) BOOL didComplete;

@property (readonly) EWCAddressIpv4 *remoteAddress;

@end
