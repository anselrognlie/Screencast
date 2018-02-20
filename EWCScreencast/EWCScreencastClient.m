//
//  EWCScreencastClient.m
//  EWCScreencast
//
//  Created by Ansel Rognlie on 2018/02/18.
//  Copyright © 2018 Ansel Rognlie. All rights reserved.
//

#import "EWCScreencastClient.h"

#import "EWCScreencastClient.h"
#import "EWCCore/Network/EWCUdpChannel+EWCUdpChannelProtected.h"

#import "EWCScreencastProtocol.h"
#import "EWCScreencastClientDelegate.h"
#import "Protocol/Packet/EWCScreencastScreenRequest.h"
#import "Protocol/Packet/EWCScreencastPrepareForData.h"
#import "Protocol/Packet/EWCScreencastAcknowledge.h"
#import "Protocol/Packet/EWCScreencastData.h"

enum EWCClientState {
    EWC_CS_STARTED,
    EWC_CS_AWAIT_PREPARE,
    EWC_CS_AWAIT_DATA,
    EWC_CS_DONE
};

@interface EWCScreencastClient()
@property uint16_t currentScreenId;
@property uint16_t completedScreenId;
@property NSMutableData *data;
@property uint32_t expectedBytes;
@property uint32_t receivedBytes;
@property EWCAddressIpv4 *channelAddress;
@end

@implementation EWCScreencastClient {
    enum EWCClientState state_;
    uint16_t expectedBlock_;
}

- (instancetype)init {
    self = [super init];

    self.currentScreenId = 0;
    self.completedScreenId = 0;
    self.data = nil;
    self.expectedBytes = 0;
    self.receivedBytes = 0;
    self.channelAddress = nil;
    state_ = EWC_CS_STARTED;
    expectedBlock_ = 0;

    return self;
}

- (void)requestScreen {
    // complete any previous outstanding operation
    [self completeAction];

    // get a screen request
    EWCScreencastScreenRequest *request;
    request = [EWCScreencastScreenRequest packetWithProviderName:self.providerName
                                                      lastScreen:self.completedScreenId];

    // convert to data
    NSData *data = [request getData];

    state_ = EWC_CS_AWAIT_PREPARE;

    // send it
    [self repeatWithTimeout:1 upTo:3 action:^{
        [self sendPacketData:data toAddress:self.remoteAddress];
    }];
}

- (NSData *)receivedDataDELETEME {
    return self.data;
}

- (void)sendAcknowledgement:(uint16_t)blockId withRetries:(uint8_t)retry {
    // send acknowledgement
    EWCScreencastAcknowledge *packet;
    packet = [EWCScreencastAcknowledge packetWithBlock:blockId];

    // convert to data
    NSData *data = [packet getData];

    // send it
    if (retry) {
        [self repeatWithTimeout:1 upTo:retry action:^{
            [self sendPacketData:data toAddress:self.channelAddress];
        }];
    } else {
        [self sendPacketData:data toAddress:self.channelAddress];
    }
}

// protected overrides ////////////////////////////////////////////////////////

- (void)handlePacketData:(NSData *)data fromAddress:(EWCAddressIpv4 *)address {
    EWCScreencastProtocol *protocol = EWCScreencastProtocol.protocol;
    [protocol handlePacketData:data fromAddress:address handler:self];
}

// protocol methods ///////////////////////////////////////////////////////////

- (void)processPrepareForData:(EWCScreencastPrepareForData *)packet
                  fromAddress:(EWCAddressIpv4 *)address {
    NSLog(@"handle prepare for data...");
    if (state_ != EWC_CS_AWAIT_PREPARE) {
        // if we weren't expecting this, ignore and resume whatever we were doing
        [self resumeAction];
        return;
    }

    state_ = EWC_CS_AWAIT_DATA;
    expectedBlock_ = 1;  // actual data starts with block 1

    // complete the action
    [self completeAction];

    // record prepare for receiving actual data
    self.currentScreenId = packet.screenId;
    self.expectedBytes = packet.byteCount;
    self.receivedBytes = 0;
    self.data = [NSMutableData dataWithCapacity:self.expectedBytes];
    self.channelAddress = address;

    // acknowledge
    [self sendAcknowledgement:0 withRetries:3];
}

- (void)processScreenRequest:(EWCScreencastScreenRequest *)packet
                 fromAddress:(EWCAddressIpv4 *)address {
    // will never receive this message
}

- (void)processAcknowledge:(EWCScreencastAcknowledge *)packet
               fromAddress:(EWCAddressIpv4 *)address {
    // will never receive this message
}

- (void)processData:(EWCScreencastData *)packet
        fromAddress:(EWCAddressIpv4 *)address {
    NSLog(@"handle data...");

    if (state_ != EWC_CS_AWAIT_DATA || packet.blockId != expectedBlock_) {
        // if we weren't expecting this, ignore and resume whatever we were doing
        [self resumeAction];
        return;
    }

    // complete the action
    [self completeAction];

    self.receivedBytes += (uint32_t)packet.data.length;
    if (self.receivedBytes > self.expectedBytes) {
        // bigger than we were expecting, so error out
        return;
    }
    [self.data appendData:packet.data];

    if (self.receivedBytes == self.expectedBytes) {
        // got all data
        state_ = EWC_CS_DONE;

        [self sendAcknowledgement:packet.blockId withRetries:0];

        NSLog(@"data complete.");
        if (self.clientDelegate) {
            [self.clientDelegate receivedScreenFromClient:self];
        }
    } else {
        // advance expected block and send ack
        ++expectedBlock_;

        [self sendAcknowledgement:packet.blockId withRetries:3];
    }
}

@end
