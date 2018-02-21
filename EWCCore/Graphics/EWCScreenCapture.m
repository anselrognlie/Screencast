//
//  EWCScreenCapture.m
//  EWCCore
//
//  Created by Ansel Rognlie on 2018/02/21.
//  Copyright © 2018 Ansel Rognlie. All rights reserved.
//

#import "EWCScreenCapture.h"

@implementation EWCScreenCapture

static CGContextRef EWCCreateBitmapContext(size_t width, size_t height);

+ (CGImageRef)createScreenCapture {
    return [EWCScreenCapture createScreenCaptureWithMaxWidth:0 maxHeight:0];
}

+ (CGImageRef)createScreenCaptureWithMaxWidth:(size_t)maxWidth
                                    maxHeight:(size_t)maxHeight {

    CGImageRef screenShot = CGWindowListCreateImage(CGRectInfinite,
                                                    kCGWindowListOptionOnScreenOnly,
                                                    kCGNullWindowID,
                                                    kCGWindowImageDefault);

    size_t h = CGImageGetHeight(screenShot);
    size_t w = CGImageGetWidth(screenShot);
    float aspect = ((float)h) / w;

    // calculate the target sizes based on the supplied dimensions
    //   1. if both are 0, just use the native size (no resize required)
    //   2. if both are provided, then base the calculation off whichever
    //      dimension will result in the largest overall image (smallest bars)
    //   3. if one dimension is provided, adjust the other side to that

    if (maxWidth == 0 && maxHeight == 0) {
        // don't release screenshot before here
        return screenShot;
    }

    size_t targetWidth = 0;
    size_t targetHeight = 0;

    if (maxWidth != 0 && maxHeight != 0) {
        // check the requested aspect ratio
        float maxAspect = ((float)maxHeight) / maxWidth;
        if (maxAspect < aspect) {
            targetHeight = maxHeight;
            targetWidth = w * (((float)maxHeight) / h);
        } else {
            targetWidth = maxWidth;
            targetHeight = h * (((float)maxWidth) / w);
        }
    } else if (maxWidth) {
        targetWidth = maxWidth;
        targetHeight = maxWidth * aspect;
    } else {  // maxHeight
        targetHeight = maxHeight;
        targetWidth = maxHeight / aspect;
    }

    // create a bitmap context to resize the image into
    CGContextRef context = EWCCreateBitmapContext(targetWidth, targetHeight);
    CGRect rect = CGRectMake(0, 0, targetWidth, targetHeight);
    CGContextDrawImage(context, rect, screenShot);

    CGImageRef resizedImage = CGBitmapContextCreateImage(context);

    CFRelease(context);
    CFRelease(screenShot);  // safe since we're returning the resized version

    return resizedImage;
}

@end

static CGContextRef EWCCreateBitmapContext(size_t width, size_t height) {
    CGContextRef context;
    CGColorSpaceRef colorSpace;

    colorSpace = CGColorSpaceCreateWithName(kCGColorSpaceGenericRGB);

    size_t bitsPerChannel = 8;
    size_t bytesPerRow = 4 * width;

    context = CGBitmapContextCreate(NULL,
        width, height, bitsPerChannel, bytesPerRow, colorSpace, kCGImageAlphaNoneSkipLast);
    CFRelease(colorSpace);

    CGContextSetInterpolationQuality(context, kCGInterpolationMedium);

    return context;
}
