//
//  EWCUdpListener+EWCUdpListenerProtected.h
//  Screencast
//
//  Created by Ansel Rognlie on 2018/02/01.
//  Copyright © 2018 Ansel Rognlie. All rights reserved.
//

#import "EWCUdpChannel.h"

@interface EWCUdpChannel (EWCUdpChannelProtected)

- (void)sendPacketTo:(struct sockaddr_in *)address
                data:(UInt8 *)data
              length:(UInt32)length;

@end

