//
//  EWCPair.m
//  Screencast
//
//  Created by Ansel Rognlie on 2018/02/06.
//  Copyright © 2018 Ansel Rognlie. All rights reserved.
//

#import "EWCPair.h"

@implementation EWCPair

+ (instancetype)pairWithFirst:(id)first second:(id)second{
    return [[EWCPair alloc] initWithFirst:first second:second];
}

- (instancetype)initWithFirst:(id)first second:(id)second {
    self = [super init];

    self.first = first;
    self.second = second;

    return self;
}

@end
