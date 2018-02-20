//
//  EWCScreencastDelegate.h
//  EWCScreencast
//
//  Created by Ansel Rognlie on 2018/02/20.
//  Copyright © 2018 Ansel Rognlie. All rights reserved.
//

#import <Foundation/Foundation.h>

@class EWCScreencast;

@protocol EWCScreencastDelegate <NSObject>

- (void)server:(EWCScreencast *)server completedSendWithSuccess:(BOOL)success;

@end
