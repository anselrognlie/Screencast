//
//  EWCServiceRegistryProtocol.h
//  Screencast
//
//  Created by Ansel Rognlie on 2018/02/06.
//  Copyright © 2018 Ansel Rognlie. All rights reserved.
//

#import <Foundation/Foundation.h>

// service port
static const uint16_t EWCServiceRegistryPort = 13887;

// forward decls
@protocol EWCServiceRegistryPacket;
@protocol EWCServiceRegistryProtocolHandler;

typedef BOOL (^EWCServiceRegistryRecognizer)(NSData* data);
typedef NSObject<EWCServiceRegistryPacket> *(^EWCServiceRegistryParser)(NSData* data,
                                                                        struct sockaddr_in const *fromAddress);

@interface EWCServiceRegistryProtocol : NSObject

@property (class, readonly) EWCServiceRegistryProtocol *protocol;

- (void)handlePacketData:(NSData *)data
             fromAddress:(struct sockaddr_in const *)address
                 handler:(NSObject<EWCServiceRegistryProtocolHandler> *)handler;

- (int)registerPacketParser:(EWCServiceRegistryParser)parser
                 recognizer:(EWCServiceRegistryRecognizer)recognizer;

- (void)unregisterPacketParser:(int)token;

@end
