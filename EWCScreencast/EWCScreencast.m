//
//  EWCScreencast.m
//  EWCScreencast
//
//  Created by Ansel Rognlie on 2018/02/15.
//  Copyright © 2018 Ansel Rognlie. All rights reserved.
//

#import "EWCScreencast.h"
#import "EWCCore/Network/EWCUdpChannel+EWCUdpChannelProtected.h"

#import "EWCScreencastProtocol.h"

@interface EWCScreencast()
@end

@implementation EWCScreencast {
}

- (void)handlePacketData:(NSData *)data fromAddress:(EWCAddressIpv4 *)address {
    EWCScreencastProtocol *protocol = EWCScreencastProtocol.protocol;
    [protocol handlePacketData:data fromAddress:address handler:self];
}

- (void)processPrepareForData:(EWCScreencastPrepareForData *)packet
                  fromAddress:(EWCAddressIpv4 *)address {

}

- (void)processScreenRequest:(EWCScreencastScreenRequest *)packet
                 fromAddress:(EWCAddressIpv4 *)address {
    
}

- (void)processAcknowledge:(EWCScreencastAcknowledge *)packet
               fromAddress:(EWCAddressIpv4 *)address {

}

- (void)processData:(EWCScreencastData *)packet
        fromAddress:(EWCAddressIpv4 *)address {

}

@end
