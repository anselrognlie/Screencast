//
//  ViewController.m
//  SimpleScreencastApp
//
//  Created by Ansel Rognlie on 2018/02/21.
//  Copyright © 2018 Ansel Rognlie. All rights reserved.
//

#import "ViewController.h"

#import "EWCCore/Device/EWCDevice.h"
#import "EWCServiceLocator/EWCServiceRegistryClient.h"
#import "EWCScreencast/EWCScreencastClient.h"
#import "EWCScreencast/Protocol/EWCScreencastProtocol.h"

@interface ViewController ()
@property NSString *machineName;
@property EWCScreencastClient *screencast;
@property EWCServiceRegistryClient *locator;
@property EWCAddressIpv4 *screencastAddress;
@property (weak, nonatomic) IBOutlet UIImageView *imageView;
@end

@implementation ViewController {
    BOOL stopped_;
}

- (void)viewDidLoad {
    [super viewDidLoad];

    stopped_ = YES;

    [self start];

    [EWCDevice scheduleNameLookupThen:^(NSString *machineName) {
        self.machineName = machineName;
        [self locateServiceAndRequestScreen];
    }];
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)start {
    if (! stopped_) { return; }

    self.screencast = [EWCScreencastClient new];
    self.screencast.clientDelegate = self;
    [self.screencast start];
    self.locator = [EWCServiceRegistryClient new];
    self.locator.clientHandler = self;
    [self.locator start];

    stopped_ = NO;
}

- (void)stop {
    if (stopped_) { return; }

    EWCScreencastClient *tmp = self.screencast;
    self.screencast = nil;
    if (tmp) {
        [tmp stop];
    }

    EWCServiceRegistryClient *tmpClient = self.locator;
    self.locator = nil;
    if (tmpClient) {
        [tmpClient stop];
    }

    stopped_ = YES;
}

- (void)locateServiceAndRequestScreen {
    if (! self.screencastAddress) {
        [self.locator queryService:EWCScreencastProtocol.protocol.serviceId];
    } else {
        // just do a request
        [self.screencast requestScreen];
    }
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

- (void)noServiceLocated:(NSUUID *)serviceId {
    // if we failed while running, reset the remote address and try again
    if (! stopped_) {
        self.screencastAddress = nil;
        [self locateServiceAndRequestScreen];
    }
}

// EWCScreencastClientDelegate methods ///////////////////////////////////////

- (void)receivedScreenFromClient:(EWCScreencastClient *)client {
    [self.imageView setImage:client.screen];

    if (! stopped_) {
        [self locateServiceAndRequestScreen];
    }
}

- (void)clientRetriesExceeded:(EWCScreencastClient *)client {
    // if we lost the connection while running, reset the remote address and try again
    if (! stopped_) {
        self.screencastAddress = nil;
        [self locateServiceAndRequestScreen];
    }
}

@end
