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
#import "EWCScreencastDataChannel.h"
#import "EWCScreencastDelegate.h"

typedef NSMutableArray<EWCScreencastDataChannel *> EWCChannelArray;

@interface EWCScreencast()
@property NSData *fakeDataToSend;
@property EWCChannelArray *activeChannels;
@end

@implementation EWCScreencast {
}

- (instancetype)init {
    self = [super init];

    // initialize cached screenshot manager
    [self fakeInit];

    self.activeChannels = [EWCChannelArray array];

    return self;
}

- (void)fakeInit {
//    NSMutableData *data = [NSMutableData dataWithCapacity:256 * 400 * sizeof(uint8_t)];
//    for (int i = 0; i < 400; ++i) {
//        for (int j = 0; j <= 255; ++j) {
//            uint8_t byte = j;
//            [data appendBytes:&byte length:sizeof(byte)];
//        }
//    }
//    self.fakeDataToSend = data;
    NSMutableData *data = [NSMutableData dataWithCapacity:5 * sizeof(uint8_t)];
    for (int i = 0; i < 5; ++i) {
        uint8_t byte = i + 'a';
        [data appendBytes:&byte length:sizeof(byte)];
    }
    self.fakeDataToSend = data;
}

- (void)removeChannel:(EWCScreencastDataChannel *)channel {
    // make sure the channel is stopped
    [channel stop];

    // find the channel in the list
    NSUInteger index = [self.activeChannels indexOfObject:channel];
    if (index != NSNotFound) {
        // get element at end
        EWCScreencastDataChannel *last = [self.activeChannels lastObject];

        // replace found element
        [self.activeChannels setObject:last atIndexedSubscript:index];

        // truncate
        [self.activeChannels removeLastObject];
    }
}

- (void)removeChannelForAddress:(EWCAddressIpv4 *)address {
    // generate a list of channels targeting this address
    // (should be only at max 1, but check for multiple anyway)

    NSMutableArray<NSNumber *> *foundIndices;
    foundIndices = [NSMutableArray<NSNumber *> array];
    [self.activeChannels enumerateObjectsUsingBlock:^(EWCScreencastDataChannel * _Nonnull channel, NSUInteger idx, BOOL * _Nonnull stop) {
        if ([channel.remoteAddress isEqual:address]) {
            [foundIndices addObject:[NSNumber numberWithUnsignedInteger:idx]];
        }
    }];

    // iterate over found indicies and remove them in reverse order
    // since we remove from the rear, removing earlier indices won't invalidate
    // later indices
    [foundIndices enumerateObjectsWithOptions:NSEnumerationReverse usingBlock:^(NSNumber * _Nonnull number, NSUInteger idx, BOOL * _Nonnull stop) {
        NSUInteger channelIdx = number.unsignedIntegerValue;
        EWCScreencastDataChannel *channel = [self.activeChannels objectAtIndex:channelIdx];
        [channel stop];
        [self.activeChannels removeObjectAtIndex:channelIdx];
    }];
}

// protected overrides ////////////////////////////////////////////////////////

- (void)handlePacketData:(NSData *)data fromAddress:(EWCAddressIpv4 *)address {
    EWCScreencastProtocol *protocol = EWCScreencastProtocol.protocol;
    [protocol handlePacketData:data fromAddress:address handler:self];
}

// protocol methods ///////////////////////////////////////////////////////////

- (void)processPrepareForData:(EWCScreencastPrepareForData *)packet
                  fromAddress:(EWCAddressIpv4 *)address {
    // handled by data channel
}

- (void)processScreenRequest:(EWCScreencastScreenRequest *)packet
                 fromAddress:(EWCAddressIpv4 *)address {
    // received a request for a screen from the client at address
    // determine the screenshot to deliver
        // if client passes 0, use most current screenshot
        // if there is no current screenshot, or client already has most current
        //   then generate a new screenshot, log it, and make it the target.
        //   Be sure to account for screen id wrap at 65535, skipping 0
    // create a data channel to serve the specified screen (ref counted) to the client
    //   the data channel will handle the prepare, data, and acks
    //   data channel will callback when complete, whether success or failure

    // if there is a new request from an address that we've already got
    // a channel for, then assume that the client didn't get the prepare
    // notification.  So first clear out any existing channel for the
    // supplied address before allocating a new one.

    [self removeChannelForAddress:address];

    EWCScreencastDataChannel *channel;
    channel = [EWCScreencastDataChannel channelToAddress:address
                                                  screen:0
                                                    data:self.fakeDataToSend
                                                 handler:self];
    [self.activeChannels addObject:channel];

    NSLog(@"starting data channel");
    [channel start];
}

- (void)processAcknowledge:(EWCScreencastAcknowledge *)packet
               fromAddress:(EWCAddressIpv4 *)address {
    // handled by data channel
}

- (void)processData:(EWCScreencastData *)packet
        fromAddress:(EWCAddressIpv4 *)address {
    // handled by data channel
}

// EWCScreencastDataChannelDelegate methods ///////////////////////////////////

- (void)notifyCompletedChannel:(EWCScreencastDataChannel *)channel {
    NSLog(@"data channel completed");
    BOOL success = channel.didComplete;
    [self removeChannel:channel];
    [self.screencastDelegate server:self completedSendWithSuccess:success];
}

@end
