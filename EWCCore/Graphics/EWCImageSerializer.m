//
//  EWCImageSerializer.m
//  EWCCore
//
//  Created by Ansel Rognlie on 2018/02/21.
//  Copyright © 2018 Ansel Rognlie. All rights reserved.
//

#import "EWCImageSerializer.h"

@implementation EWCImageSerializer

+ (NSData *)createPngFromImage:(CGImageRef)image {
    return [EWCImageSerializer serializeImage:image asType:@"public.png"];
}

+ (NSData *)serializeImage:(CGImageRef)image asType:(NSString *)type {
    CFStringRef cfType = (__bridge CFStringRef)type;  // don't release
    CFMutableDataRef data = CFDataCreateMutable(kCFAllocatorDefault, 0);
    CGImageDestinationRef imgDest = CGImageDestinationCreateWithData(data, cfType, 1, NULL);
    CGImageDestinationAddImage(imgDest, image, NULL);

    NSData *returnData = nil;
    if (CGImageDestinationFinalize(imgDest)) {
        returnData = (__bridge_transfer NSData *)data;  // so don't release data
    } else {
        CFRelease(data);
    }

    CFRelease(imgDest);

    return returnData;
}

@end
