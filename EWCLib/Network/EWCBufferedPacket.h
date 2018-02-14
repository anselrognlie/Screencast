//
//  EWCBufferedPacket.h
//  Screencast
//
//  Created by Ansel Rognlie on 2018/02/02.
//  Copyright © 2018 Ansel Rognlie. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface EWCBufferedPacket : NSObject

@property (readonly) CFDataRef data;
@property (readonly) CFDataRef address;

+ (instancetype)packetWithData:(CFDataRef)data address:(CFDataRef)address;

- (instancetype)initWithData:(CFDataRef)data address:(CFDataRef)address;

@end
