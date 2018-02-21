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

@class EWCAddressIpv4;
@protocol EWCScreencastClientDelegate;

@interface EWCScreencastClient : EWCUdpChannel<EWCScreencastProtocolHandler>

- (void)requestScreen;

@property NSString *providerName;
@property EWCAddressIpv4 *remoteAddress;
@property (weak) NSObject<EWCScreencastClientDelegate> *clientDelegate;
@property (readonly) NSData *receivedDataDELETEME;
@property (readonly) NSImage *screen;

@end
