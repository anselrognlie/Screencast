//
//  EWCScreencastProtocol.h
//  EWCScreencat
//
//  Created by Ansel Rognlie on 2018/02/15.
//  Copyright © 2018 Ansel Rognlie. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "EWCCore/Network/EWCAddressIpv4.h"

// service port
static const uint16_t EWCScreencastPort = 13888;

// forward decls
@protocol EWCScreencastPacket;
@protocol EWCScreencastProtocolHandler;

typedef BOOL (^EWCScreencastRecognizer)(NSData* data);
typedef NSObject<EWCScreencastPacket> *(^EWCScreencastParser)(NSData* data,
                                                              EWCAddressIpv4 *fromAddress);

@interface EWCScreencastProtocol : NSObject

@property (class, readonly) EWCScreencastProtocol *protocol;

@property (readonly) NSUUID *serviceId;

- (void)handlePacketData:(NSData *)data
             fromAddress:(EWCAddressIpv4 *)address
                 handler:(NSObject<EWCScreencastProtocolHandler> *)handler;

- (int)registerPacketParser:(EWCScreencastParser)parser
                 recognizer:(EWCScreencastRecognizer)recognizer;

- (void)unregisterPacketParser:(int)token;


@end
