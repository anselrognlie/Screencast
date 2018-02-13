//
//  ViewController.m
//  Screencast
//
//  Created by Ansel Rognlie on 2018/01/29.
//  Copyright © 2018 Ansel Rognlie. All rights reserved.
//

#import "ViewController.h"

#import "EWCServiceRegistry.h"
#import "EWCServiceRegistryClient.h"

static const NSInteger TAG_SERVICEID_TEXTFIELD  = 1;
static const NSInteger TAG_PORT_TEXTFIELD  = 2;

static const uint16_t DEFAULT_PORT = 9999;
static const char DEFAULT_SERVICEID_STRING[] = "C4015E7D-CCC5-49E7-954B-0036D8C2CC04";

@interface ViewController()

@property EWCServiceRegistry *registry;
@property EWCServiceRegistryClient *publisher;

@property NSString *machineName;
@property NSUUID *currentServiceId;
@property uint16_t currentPort;
@property (unsafe_unretained) IBOutlet NSTextView *resultText;
@property NSString *queryResult;

@end

@implementation ViewController {
    BOOL stopped_;
}

- (void)dealloc{
    [self stop];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    stopped_ = YES;
    self.machineName = nil;

    // schedule a local name lookup
    [self scheduleNameLookupAndThen:^{}];

    [self populateUI];
    
    [self start];
}

- (void)populateUI {
    NSTextField *field = [self getServiceIdTextField];
    field.stringValue = [NSString stringWithUTF8String:DEFAULT_SERVICEID_STRING];
    [self changedServiceIdTextField:field];

    field = [self getPortTextField];
    field.stringValue = [NSString stringWithFormat:@"%d", DEFAULT_PORT];
    [self changedPortTextField:field];
}

- (void)setRepresentedObject:(id)representedObject {
    [super setRepresentedObject:representedObject];
    
    // Update the view, if already loaded.
}

- (void)viewWillDisappear {
    // don't stop everything, since this happens even on minimize
}


- (void)start {
    if (! stopped_) { return; }
    
    self.registry = [EWCServiceRegistry new];
    [self.registry start];
    self.publisher = [EWCServiceRegistryClient new];
    self.publisher.clientHandler = self;
    [self.publisher start];
}

- (void)stop {
    if (stopped_) { return; }
    
    EWCServiceRegistry *tmp = self.registry;
    self.registry = nil;
    if (tmp) {
        [tmp stop];
    }

    EWCServiceRegistryClient *tmpClient = self.publisher;
    self.publisher = nil;
    if (tmpClient) {
        [tmpClient stop];
    }
}

- (void)publishService {
    NSUUID *serviceId = self.currentServiceId;
    uint16_t port = self.currentPort;
    NSString *provider = self.machineName;

    if (! provider) { return; }
    if (! serviceId) { return; }
    if (! port) { return; }

    [self.publisher registerService:serviceId providerName:provider port:port];
    NSLog(@"published");
}

- (void)unpublishService {
    NSUUID *serviceId = self.currentServiceId;
    uint16_t port = self.currentPort;

    if (! serviceId) { return; }
    if (! port) { return; }

    [self.publisher unregisterService:serviceId port:port];
    NSLog(@"unpublished");
}

- (void)queryService {
    NSUUID *serviceId = self.currentServiceId;

    if (! serviceId) { return; }

    // clear the current result
    self.queryResult = nil;
    [self updateQueryResult];

    [self.publisher queryService:serviceId];
    NSLog(@"queried");
}

- (void)scheduleNameLookupAndThen:(void(^)(void))continuation {
    dispatch_queue_t dq = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);

    dispatch_async(dq, ^{
        NSHost *host = [NSHost currentHost];
        NSString *hostName = host.localizedName;
        NSLog(@"got hostname");

        dispatch_async(dispatch_get_main_queue(), ^{
            self.machineName = hostName;
            continuation();
        });
    });
}

- (void)updateQueryResult {
    NSTextView *resultField = self.resultText;
    NSString *msg = self.queryResult;
    if (! msg) {
        msg = [NSString string];
    }


    if (resultField) {
        resultField.string = msg;
    }
}

// EWCServiceRegistryClientDelegate methods /////////////////////////////////////

- (void)receivedRegistrationAcknowledgementPacket:(EWCServiceRegistryAcknowledge *)packet
                                      fromAddress:(EWCAddressIpv4 *)address {
    NSLog(@"view controller ack callback");
}

- (void)receivedLocationResponsePacket:(EWCServiceRegistryLocationResponse *)packet
                           fromAddress:(EWCAddressIpv4 *)address {
    NSLog(@"view controller location callback");

    uint32_t addr = packet.address.addressIpv4;
    uint8_t *byte = (uint8_t *)&addr;
    NSString *msg = [NSString stringWithFormat:@"%@\n  at %d.%d.%d.%d:%d (%@)",
        packet.serviceId,
        byte[3], byte[2], byte[1], byte[0],
        packet.address.port,
        packet.providerName];

    NSString *currMsg = self.queryResult;
    if (! currMsg) {
        currMsg = msg;
    } else {
        currMsg = [NSString stringWithFormat:@"%@\n%@", currMsg, msg];
    }

    self.queryResult = currMsg;

    [self updateQueryResult];
}

// control accessors /////////////////////////////////////////////////////////

- (NSTextField *)getServiceIdTextField {
    return [self.view viewWithTag:TAG_SERVICEID_TEXTFIELD];
}

- (NSTextField *)getPortTextField {
    return [self.view viewWithTag:TAG_PORT_TEXTFIELD];
}

// control handlers //////////////////////////////////////////////////////////

- (void)controlTextDidChange:(NSNotification *)obj {
    // which control?
    NSTextField *field = obj.object;
    switch (field.tag) {
        case TAG_SERVICEID_TEXTFIELD:
            [self changedServiceIdTextField:field];
        break;

        case TAG_PORT_TEXTFIELD:
            [self changedPortTextField:field];
        break;
    }
}

- (void)changedServiceIdTextField:(NSTextField *)field {
    // try to interpret the contents as a NSUUID
    NSUUID *serviceId = [[NSUUID alloc] initWithUUIDString:field.stringValue];

    self.currentServiceId = serviceId;
    if (! serviceId) {
        field.textColor = [NSColor redColor];
    } else {
        field.textColor = [NSColor textColor];
    }
}

- (void)changedPortTextField:(NSTextField *)field {
    // try to interpret the contents as a word
    uint16_t port = (uint16_t)field.intValue;

    if ([field.stringValue isEqualToString:[NSString stringWithFormat:@"%d", port]]) {
        self.currentPort = port;
        field.textColor = [NSColor textColor];
    } else {
        self.currentPort = 0;
        field.textColor = [NSColor redColor];
    }
}

- (IBAction)generateButtonClicked:(NSButton *)sender {
    NSUUID *newId = [NSUUID new];
    NSTextField *field = [self getServiceIdTextField];
    field.stringValue = [NSString stringWithFormat:@"%@", newId];
    [self changedServiceIdTextField:field];
}

- (IBAction)registerButtonClicked:(NSButton *)sender {
    [self publishService];
}

- (IBAction)unregisterButtonClicked:(NSButton *)sender {
    [self unpublishService];
}

- (IBAction)queryButtonClicked:(NSButton *)sender {
    [self queryService];
}

@end
