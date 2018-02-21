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
#import "EWCCapturedScreenRecord.h"
#import "Protocol/Packet/EWCScreencastScreenRequest.h"
#import "EWCCore/Graphics/EWCScreenCapture.h"
#import "EWCCore/Graphics/EWCImageSerializer.h"

typedef NSMutableArray<EWCScreencastDataChannel *> EWCChannelArray;

@interface EWCScreencast()
@property EWCChannelArray *activeChannels;
@property EWCCapturedScreenRecord *lastScreen;
@end

@implementation EWCScreencast {
}

- (void)startOnRunLoop:(NSRunLoop *)runLoop {
    _lastScreen = 0;

    [super startOnRunLoop:runLoop];
}

- (instancetype)init {
    self = [super init];

    self.activeChannels = [EWCChannelArray array];

    return self;
}

- (NSData *)captureScreen {

    // consider ways of tuning the target size to the available bandwidth?
    size_t targetWidth = 1920 / 8;
//    size_t targetWidth = 0;
    CGImageRef image = [EWCScreenCapture createScreenCaptureWithMaxWidth:targetWidth maxHeight:0];
    NSData *data = [EWCImageSerializer createPngFromImage:image];
    CFRelease(image);

    return data;
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

- (EWCCapturedScreenRecord *)nextScreenRecordFromId:(uint16_t)screenId {
    // determine the screenshot to deliver
        // if client passes 0, use most current screenshot
        // if there is no current screenshot, or client already has most current
        //   then generate a new screenshot, log it, and make it the target.
        //   Be sure to account for screen id wrap at 65535, skipping 0

    EWCCapturedScreenRecord *record = self.lastScreen;

    if (record && screenId != record.screenId) {
        return record;
    }

    uint16_t nextScreenId = 1;
    if (record) {
        if (record.screenId < 65535) {
            nextScreenId = record.screenId + 1;
        }
    }

    // need a new screen
    record = [EWCCapturedScreenRecord new];
    record.imageData = [self captureScreen];
    record.screenId = nextScreenId;

    self.lastScreen = record;

    return record;
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
    EWCCapturedScreenRecord *record = [self nextScreenRecordFromId:packet.screenId];

    // if there is a new request from an address that we've already got
    // a channel for, then assume that the client didn't get the prepare
    // notification.  So first clear out any existing channel for the
    // supplied address before allocating a new one.

    [self removeChannelForAddress:address];

    // create a data channel to serve the specified screen (ref counted) to the client
    //   the data channel will handle the prepare, data, and acks
    //   data channel will callback when complete, whether success or failure

    EWCScreencastDataChannel *channel;
    channel = [EWCScreencastDataChannel channelToAddress:address
                                                  screen:record.screenId
                                                    data:record.imageData
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
