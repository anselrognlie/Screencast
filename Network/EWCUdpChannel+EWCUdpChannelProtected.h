//
//  EWCUdpListener+EWCUdpListenerProtected.h
//  Screencast
//
//  Created by Ansel Rognlie on 2018/02/01.
//  Copyright © 2018 Ansel Rognlie. All rights reserved.
//

#import "EWCUdpChannel.h"

@interface EWCUdpChannel (EWCUdpChannelProtected)

- (void)sendPacketData:(NSData *)data
              toAddress:(struct sockaddr_in *)address;

@end

