//
//  EWCScreencastClientDelegate.h
//  EWCScreencast
//
//  Created by Ansel Rognlie on 2018/02/20.
//  Copyright © 2018 Ansel Rognlie. All rights reserved.
//

#import <Foundation/Foundation.h>

@class EWCScreencastClient;

@protocol EWCScreencastClientDelegate <NSObject>

- (void)receivedScreenFromClient:(EWCScreencastClient *)client;

@end

