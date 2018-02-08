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

@interface ViewController()

@property EWCServiceRegistry *registry;
@property EWCServiceRegistryClient *publisher;

@property NSString *machineName;

@end

@implementation ViewController {
    BOOL stopped_;
    BOOL published_;
}

- (void)dealloc{
    [self stop];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    stopped_ = YES;
    published_ = NO;
    self.machineName = nil;

    // schedule a local name lookup
    [self scheduleNameLookupAndThen:^{
        [self publishService];
    }];
    
    [self start];
    [self publishService];
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
    static int called = 0;
    NSLog(@"publish count: %d", ++called);
    if (published_) { return; }
    if (! self.machineName) { return; }

    NSUUID *serviceId = [[NSUUID alloc] initWithUUIDString:@"C4015E7D-CCC5-49E7-954B-0036D8C2CC04"];
    uint16_t port = 9999;
    NSString *provider = self.machineName;

    [self.publisher registerService:serviceId providerName:provider port:port];
    NSLog(@"published");

    published_ = YES;
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

@end
