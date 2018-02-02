//
//  ViewController.m
//  Screencast
//
//  Created by Ansel Rognlie on 2018/01/29.
//  Copyright © 2018 Ansel Rognlie. All rights reserved.
//

#import "ViewController.h"

#import "EWCServiceRegistry.h"

@interface ViewController()

@property EWCServiceRegistry *registry;

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
    
    [self start];
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
}

- (void)stop {
    if (stopped_) { return; }
    
    EWCServiceRegistry *tmp = self.registry;
    self.registry = nil;
    if (tmp) {
        [tmp stop];
    }
}

@end
