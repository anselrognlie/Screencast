//
//  ViewController.m
//  SimpleScreencastClient
//
//  Created by Ansel Rognlie on 2018/02/18.
//  Copyright © 2018 Ansel Rognlie. All rights reserved.
//

#import "ViewController.h"

#import "EWCCore/Device/EWCDevice.h"
#import "EWCServiceLocator/EWCServiceRegistryClient.h"
#import "EWCScreencast/EWCScreencastClient.h"
#import "EWCScreencast/Protocol/EWCScreencastProtocol.h"

static const NSInteger TAG_REQUEST_BUTTON  = 1;

@interface ViewController()
@property NSString *machineName;
@property EWCScreencastClient *screencast;
@property EWCServiceRegistryClient *publisher;
@property EWCAddressIpv4 *screencastAddress;
@property (weak) IBOutlet NSTextField *addressLabel;
@property (weak) IBOutlet NSTextField *receivedCount;
@property (weak) IBOutlet NSButton *continuousCheckbox;
@end

@implementation ViewController {
    BOOL stopped_;
    int screensReceived_;
    BOOL running_;
}

- (void)viewDidLoad {
    [super viewDidLoad];

    stopped_ = YES;

    [self start];

    [EWCDevice scheduleNameLookupThen:^(NSString *machineName) {
        self.machineName = machineName;
        // possibly enable ui here
    }];
}

- (void)setRepresentedObject:(id)representedObject {
    [super setRepresentedObject:representedObject];

    // Update the view, if already loaded.
}

- (void)start {
    if (! stopped_) { return; }

    self.screencast = [EWCScreencastClient new];
    self.screencast.clientDelegate = self;
    [self.screencast start];
    self.publisher = [EWCServiceRegistryClient new];
    self.publisher.clientHandler = self;
    [self.publisher start];

    self.addressLabel.stringValue = [[self.screencast getBoundAddress] description];

    stopped_ = NO;
    screensReceived_ = 0;
    running_ = NO;
}

- (void)stop {
    if (stopped_) { return; }

    EWCScreencastClient *tmp = self.screencast;
    self.screencast = nil;
    if (tmp) {
        [tmp stop];
    }

    EWCServiceRegistryClient *tmpClient = self.publisher;
    self.publisher = nil;
    if (tmpClient) {
        [tmpClient stop];
    }

    stopped_ = YES;
}

- (void)locateServiceAndRequestScreen {
    if (! self.screencastAddress) {
        [self.publisher queryService:EWCScreencastProtocol.protocol.serviceId];
    } else {
        // just do a request
        [self.screencast requestScreen];
    }
}

// ui element methods /////////////////////////////////////////////////////////

- (NSButton *)getRequestButton {
    return [self.view viewWithTag:TAG_REQUEST_BUTTON];
}

- (IBAction)requestButtonClicked:(NSButton *)sender {
    running_ = YES;
    [self locateServiceAndRequestScreen];
}

- (IBAction)stopButtonClicked:(NSButton *)sender {
    running_ = NO;
    self.screencastAddress = nil;
}

// EWCServiceRegistryClientDelegate methods ///////////////////////////////////

- (void)receivedLocationResponsePacket:(EWCServiceRegistryLocationResponse *)packet
                           fromAddress:(EWCAddressIpv4 *)address {
    self.screencastAddress = packet.address;

    self.screencast.remoteAddress = self.screencastAddress;
    self.screencast.providerName = self.machineName;

    [self.screencast requestScreen];
}

- (void)receivedRegistrationAcknowledgementPacket:(EWCServiceRegistryAcknowledge *)packet
                                      fromAddress:(EWCAddressIpv4 *)address {
    // no implementation required since we aren't registering
}

// EWCScreencastClientDelegate methods ///////////////////////////////////////

- (void)receivedScreenFromClient:(EWCScreencastClient *)client {
    ++screensReceived_;
    self.receivedCount.intValue = screensReceived_;

    if (self.continuousCheckbox.state == NSControlStateValueOn) {
        [self locateServiceAndRequestScreen];
    }
}

@end
