//
//  EWCScreencastDataChannel.m
//  EWCScreencast
//
//  Created by Ansel Rognlie on 2018/02/17.
//  Copyright © 2018 Ansel Rognlie. All rights reserved.
//

#import "EWCScreencastDataChannel.h"
#import "EWCCore/Network/EWCUdpChannel+EWCUdpChannelProtected.h"

#import "EWCScreencastProtocol.h"
#import "EWCScreencastDataChannelDelegate.h"
#import "Protocol/Packet/EWCScreencastPrepareForData.h"
#import "Protocol/Packet/EWCScreencastAcknowledge.h"
#import "Protocol/Packet/EWCScreencastData.h"
#import "EWCCore/Network/EWCAddressIpv4.h"

enum EWCDataChannelState {
    EWC_DCS_STARTED,
    EWC_DCS_AWAIT_PREPARE_ACK,
    EWC_DCS_AWAIT_DATA_ACK,
    EWC_DCS_DONE,
    EWC_DCS_STOPPED,
    EWC_DCS_TIMEOUT,
};

static const int MAX_DATA_BYTES = 400;
static int instanceCount = 0;

@interface EWCScreencastDataChannel()
@property uint16_t screenId;
@property NSData *data;
@property (weak) NSObject<EWCScreencastDataChannelDelegate> *handler;
@property EWCAddressIpv4 *remoteAddress;
@end

@implementation EWCScreencastDataChannel {
    enum EWCDataChannelState state_;
    uint16_t expectedBlock_;
    uint32_t sentBytes_;
    BOOL sentFinalPacket_;
}

+ (uint16_t)count {
    return instanceCount;
}

+ (instancetype)channelToAddress:(EWCAddressIpv4 *)address
                          screen:(uint16_t)screenId
                            data:(NSData *)data
                         handler:(NSObject<EWCScreencastDataChannelDelegate> *)handler {
    EWCScreencastDataChannel *channel = [[EWCScreencastDataChannel alloc]
                                         initToAddress:address
                                         screen:screenId
                                         data:data
                                         handler:handler];

    return channel;
}

- (instancetype)init {
    return nil;
}

- (instancetype)initToAddress:(EWCAddressIpv4 *)address
                       screen:(uint16_t)screenId
                         data:(NSData *)data
                      handler:(NSObject<EWCScreencastDataChannelDelegate> *)handler {
    self = [super init];

    ++instanceCount;

    self.remoteAddress = address;
    self.screenId = screenId;
    self.data = data;
    self.handler = handler;

    state_ = EWC_DCS_STARTED;

    return self;
}

- (BOOL)didComplete {
    return state_ == EWC_DCS_DONE;
}

- (void)stop {
    [super stop];

    self.remoteAddress = nil;
    self.screenId = 0;
    self.data = nil;
    self.handler = nil;

    state_ = EWC_DCS_STOPPED;
}

- (void)sendPrepareForData {
    EWCScreencastPrepareForData *packet;
    packet = [EWCScreencastPrepareForData packetWithScreenId:self.screenId
                                                   byteCount:(uint32_t)self.data.length];

    // convert to data
    NSData *data = [packet getData];

    state_ = EWC_DCS_AWAIT_PREPARE_ACK;
    expectedBlock_ = 0;
    sentBytes_ = 0;
    sentFinalPacket_ = NO;

    __weak EWCScreencastDataChannel *me = self;

    // send it
    [self repeatWithTimeout:1 upTo:3 action:^{
        [me sendPacketData:data toAddress:me.remoteAddress];
    }];
}

- (void)sendNextData {
    // see whether we're done
    if (sentFinalPacket_) {
        [self.handler notifyCompletedChannel:self];
        return;
    }

    // extract data for the packet from the main data
    NSUInteger start = expectedBlock_ * MAX_DATA_BYTES;
    NSUInteger len = MIN(MAX_DATA_BYTES, self.data.length - start);
    NSData *packetData = [NSData dataWithData:[self.data
                                               subdataWithRange:NSMakeRange(start, len)]];
    sentBytes_ += len;
    sentFinalPacket_ = (sentBytes_ == self.data.length);

    // advance the block this will be
    ++expectedBlock_;

    EWCScreencastData *packet;
    packet = [EWCScreencastData packetWithBlock:expectedBlock_ data:packetData];

    // convert to data
    NSData *data = [packet getData];

    state_ = EWC_DCS_AWAIT_DATA_ACK;

    __weak EWCScreencastDataChannel *me = self;

    // send it
    [self repeatWithTimeout:1 upTo:3 action:^{
        NSLog(@"sending data to: %@. block: %d", me.remoteAddress, packet.blockId);
        [me sendPacketData:data toAddress:me.remoteAddress];
    }];
}

- (void)processDataAcknowledge:(EWCScreencastAcknowledge *)packet
                   fromAddress:(EWCAddressIpv4 *)address {
    // make sure the ack was for the expected block
    [self processAcknowledge:packet block:expectedBlock_ fromAddress:address];
}

- (void)processAcknowledge:(EWCScreencastAcknowledge *)packet
                     block:(uint16_t)blockId
               fromAddress:(EWCAddressIpv4 *)address {
    // make sure the ack was for the expected block
    if (packet.block == blockId && [address isEqual:self.remoteAddress]) {
        NSLog(@"valid ack");
        [self completeAction];

        if (! sentFinalPacket_) {
            [self sendNextData];
        } else {
            state_ = EWC_DCS_DONE;
            [self.handler notifyCompletedChannel:self];
        }
    } else {
        // otherwise this wasn't expected so continue the retry
        NSLog(@"invalid ack");
        [self resumeAction];
    }
}

// protected overrides ////////////////////////////////////////////////////////

- (void)startOnRunLoop:(NSRunLoop *)runLoop {
    [super startOnRunLoop:runLoop];

    [self sendPrepareForData];
}

- (void)handlePacketData:(NSData *)data fromAddress:(EWCAddressIpv4 *)address {
    EWCScreencastProtocol *protocol = EWCScreencastProtocol.protocol;
    [protocol handlePacketData:data fromAddress:address handler:self];
}

- (void)handleTimeout {
}

- (void)handleRetriesExceeded {
    // couldn't complete the transmission, so just terminate the channel
    NSLog(@"lost connection.");
    state_ = EWC_DCS_TIMEOUT;
    [self.handler notifyCompletedChannel:self];
}

// protocol methods ///////////////////////////////////////////////////////////

- (void)processPrepareForData:(EWCScreencastPrepareForData *)packet
                  fromAddress:(EWCAddressIpv4 *)address {
    // issues this message, not receive
}

- (void)processScreenRequest:(EWCScreencastScreenRequest *)packet
                 fromAddress:(EWCAddressIpv4 *)address {
    // should never receive this message
}

- (void)processAcknowledge:(EWCScreencastAcknowledge *)packet
               fromAddress:(EWCAddressIpv4 *)address {
    NSLog(@"received ack. block: %d", packet.block);
    switch (state_) {
        case EWC_DCS_AWAIT_PREPARE_ACK:
        case EWC_DCS_AWAIT_DATA_ACK:
            [self processDataAcknowledge:packet fromAddress:address];
            break;

        case EWC_DCS_STARTED:
        case EWC_DCS_DONE:
        case EWC_DCS_STOPPED:
        case EWC_DCS_TIMEOUT:
        default:
            // unknown state, we shouldn't be expecting an ack
            // just shutdown
            NSLog(@"unexpected channel state.");
            [self.handler notifyCompletedChannel:self];
            break;
    }
}

- (void)processData:(EWCScreencastData *)packet
        fromAddress:(EWCAddressIpv4 *)address {
    // issues this message, not receive
}

@end
