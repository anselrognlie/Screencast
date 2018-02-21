//
//  EWCScreenCapture.h
//  EWCCore
//
//  Created by Ansel Rognlie on 2018/02/21.
//  Copyright © 2018 Ansel Rognlie. All rights reserved.
//

#import <Foundation/Foundation.h>

#if TARGET_OS_IOS == 1
#import <CoreGraphics/CoreGraphics.h>
#endif

@interface EWCScreenCapture : NSObject

+ (CGImageRef)createScreenCapture;

+ (CGImageRef)createScreenCaptureWithMaxWidth:(size_t)maxWidth
                                    maxHeight:(size_t)maxHeight;

@end
