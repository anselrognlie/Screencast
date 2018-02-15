//
//  EWCScreencastPacket.h
//  EWCScreencat
//
//  Created by Ansel Rognlie on 2018/02/15.
//  Copyright © 2018 Ansel Rognlie. All rights reserved.
//

#import <Foundation/Foundation.h>

@class EWCAddressIpv4;

// forward decl
@protocol EWCScreencastProtocolHandler;

@protocol EWCScreencastPacket <NSObject>

@property (readonly) uint16_t opcode;

- (void)processWithHandler:(NSObject<EWCScreencastProtocolHandler> *)handler
               fromAddress:(EWCAddressIpv4 *)address;

@end

