//
//  EWCScreencastClient.h
//  EWCScreencast
//
//  Created by Ansel Rognlie on 2018/02/18.
//  Copyright © 2018 Ansel Rognlie. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "EWCCore/Network/EWCUdpChannel.h"
#import "Protocol/EWCScreencastProtocolHandler.h"

#if TARGET_OS_IOS == 1
@class UIImage;
#endif

@class EWCAddressIpv4;
@protocol EWCScreencastClientDelegate;

@interface EWCScreencastClient : EWCUdpChannel<EWCScreencastProtocolHandler>

- (void)requestScreen;

@property NSString *providerName;
@property EWCAddressIpv4 *remoteAddress;
@property (weak) NSObject<EWCScreencastClientDelegate> *clientDelegate;

#if TARGET_OS_IOS == 1
@property (readonly) UIImage *screen;
#else
@property (readonly) NSImage *screen;
#endif

@end
