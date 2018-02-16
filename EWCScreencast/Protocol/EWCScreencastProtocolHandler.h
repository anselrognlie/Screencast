//
//  EWCScreencastProtocolHandler.h
//  EWCScreencat
//
//  Created by Ansel Rognlie on 2018/02/15.
//  Copyright © 2018 Ansel Rognlie. All rights reserved.
//

#import <Foundation/Foundation.h>

@class EWCScreencastScreenRequest;
@class EWCScreencastPrepareForData;
@class EWCScreencastAcknowledge;
@class EWCScreencastData;
@class EWCAddressIpv4;

@protocol EWCScreencastProtocolHandler <NSObject>

- (void)processScreenRequest:(EWCScreencastScreenRequest *)packet
                 fromAddress:(EWCAddressIpv4 *)address;
- (void)processPrepareForData:(EWCScreencastPrepareForData *)packet
                  fromAddress:(EWCAddressIpv4 *)address;
- (void)processAcknowledge:(EWCScreencastAcknowledge *)packet
               fromAddress:(EWCAddressIpv4 *)address;
- (void)processData:(EWCScreencastData *)packet
        fromAddress:(EWCAddressIpv4 *)address;

@end
