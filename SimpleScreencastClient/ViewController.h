//
//  ViewController.h
//  SimpleScreencastClient
//
//  Created by Ansel Rognlie on 2018/02/18.
//  Copyright © 2018 Ansel Rognlie. All rights reserved.
//

#import <Cocoa/Cocoa.h>

#import "EWCServiceLocator/EWCServiceRegistryClientDelegate.h"
#import "EWCScreencast/EWCScreencastClientDelegate.h"

@interface ViewController : NSViewController<EWCServiceRegistryClientDelegate, EWCScreencastClientDelegate>


@end

