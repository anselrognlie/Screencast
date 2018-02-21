//
//  ViewController.h
//  SimpleScreencastApp
//
//  Created by Ansel Rognlie on 2018/02/21.
//  Copyright © 2018 Ansel Rognlie. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "EWCServiceLocator/EWCServiceRegistryClientDelegate.h"
#import "EWCScreencast/EWCScreencastClientDelegate.h"

@interface ViewController : UIViewController<EWCServiceRegistryClientDelegate, EWCScreencastClientDelegate>


@end

