//
//  EWCCapturedScreenRecord.h
//  EWCScreencast
//
//  Created by Ansel Rognlie on 2018/02/21.
//  Copyright © 2018 Ansel Rognlie. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface EWCCapturedScreenRecord : NSObject

@property NSData *imageData;
@property uint16_t screenId;

@end
