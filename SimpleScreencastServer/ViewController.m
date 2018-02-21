//
//  ViewController.m
//  SimpleScreencastServer
//
//  Created by Ansel Rognlie on 2018/02/18.
//  Copyright © 2018 Ansel Rognlie. All rights reserved.
//

#import "ViewController.h"

#import "EWCCore/Device/EWCDevice.h"
#import "EWCServiceLocator/EWCServiceRegistry.h"
#import "EWCServiceLocator/EWCServiceRegistryClient.h"
#import "EWCScreencast/EWCScreencast.h"
#import "EWCScreencast/Protocol/EWCScreencastProtocol.h"

@interface ViewController()
@property EWCScreencast *screencast;
@property EWCServiceRegistryClient *publisher;
@property EWCServiceRegistry *registry;
@property NSString *machineName;
@property (weak) IBOutlet NSTextField *addressLabel;
@property (weak) IBOutlet NSTextField *successCount;
@property (weak) IBOutlet NSTextField *failureCount;
@end

@implementation ViewController {
    BOOL stopped_;
    int successes_;
    int failures_;
}

- (void)viewDidLoad {
    [super viewDidLoad];

    stopped_ = YES;

    //[self start];
}


- (void)setRepresentedObject:(id)representedObject {
    [super setRepresentedObject:representedObject];

    // Update the view, if already loaded.
}

- (void)start {
    if (! stopped_) { return; }

    self.screencast = [EWCScreencast new];
    self.screencast.screencastDelegate = self;
    [self.screencast start];
    self.registry = [EWCServiceRegistry new];
    [self.registry start];
    self.publisher = [EWCServiceRegistryClient new];
    self.publisher.clientHandler = self;
    [self.publisher start];

    [EWCDevice scheduleNameLookupThen:^(NSString *machineName) {
        self.machineName = machineName;
        [self registerScreencast];
    }];

    stopped_ = NO;
    successes_ = 0;
    failures_ = 0;
}

- (void)stop {
    if (stopped_) { return; }

    EWCScreencast *tmp = self.screencast;
    self.screencast = nil;
    if (tmp) {
        [tmp stop];
    }

    EWCServiceRegistryClient *tmpClient = self.publisher;
    self.publisher = nil;
    if (tmpClient) {
        [tmpClient stop];
    }

    EWCServiceRegistry *tmpRegistry = self.registry;
    self.registry = nil;
    if (tmpRegistry) {
        [tmpRegistry stop];
    }

    stopped_ = YES;
}

- (void)registerScreencast {
    EWCScreencastProtocol *protocol = EWCScreencastProtocol.protocol;

    EWCAddressIpv4 *address = [self.screencast getBoundAddress];
    [self.publisher registerService:protocol.serviceId
                       providerName:self.machineName port:address.port];
}

// EWCServiceRegistryClientDelegate methods ///////////////////////////////////

- (void)receivedLocationResponsePacket:(EWCServiceRegistryLocationResponse *)packet
                           fromAddress:(EWCAddressIpv4 *)address {
    // no implementation required since we aren't querying
}

- (void)receivedRegistrationAcknowledgementPacket:(EWCServiceRegistryAcknowledge *)packet
                                      fromAddress:(EWCAddressIpv4 *)address {
    // possibly re-register self when timeout approaches
}

- (void)noServiceLocated:(NSUUID *)serviceId {
    // not used, since we just register, not query
}


// ui methods /////////////////////////////////////////////////////////////////

- (IBAction)startButtonClicked:(NSButton *)sender {
    [self start];
}

- (IBAction)stopButtonClicked:(NSButton *)sender {
    [self stop];
}

// EWCScreencastDelegate methods //////////////////////////////////////////////

- (void)server:(EWCScreencast *)server completedSendWithSuccess:(BOOL)success {
    successes_ += ((success) ? 1 : 0);
    failures_ += ((success) ? 0 : 1);

    self.successCount.intValue = successes_;
    self.failureCount.intValue = failures_;
}

@end
