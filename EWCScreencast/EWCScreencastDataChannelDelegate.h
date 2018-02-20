//
//  EWCScreencastDataChannelDelegate.h
//  EWCScreencast
//
//  Created by Ansel Rognlie on 2018/02/18.
//  Copyright © 2018 Ansel Rognlie. All rights reserved.
//

#import <Foundation/Foundation.h>

@class EWCScreencastDataChannel;

@protocol EWCScreencastDataChannelDelegate <NSObject>

- (void)notifyCompletedChannel:(EWCScreencastDataChannel *)channel;

@end
