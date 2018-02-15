//
//  EWCScreencast.h
//  EWCScreencast
//
//  Created by Ansel Rognlie on 2018/02/15.
//  Copyright © 2018 Ansel Rognlie. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "EWCCore/Network/EWCUdpChannel.h"
#import "EWCScreencastProtocolHandler.h"

@interface EWCScreencast : EWCUdpChannel <EWCScreencastProtocolHandler>

@end

