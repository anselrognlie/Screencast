//
//  EWCStringLimiter.m
//  Screencast
//
//  Created by Ansel Rognlie on 2018/02/08.
//  Copyright © 2018 Ansel Rognlie. All rights reserved.
//

#import "EWCStringLimiter.h"

@implementation EWCStringLimiter

+ (NSString *)cutString:(NSString *)string toFitBytes:(int)utf8Bytes {
    // if the current string already fits in the specified bytes, just return it
    NSUInteger len = [string lengthOfBytesUsingEncoding:NSUTF8StringEncoding];
    if (len <= utf8Bytes) {
        return string;
    }

    // otherwises, we need to walk through the string on grapheme clusters
    // to find the largest place to split the string that will still fit

    NSUInteger strlen = string.length;
    NSUInteger lastPos = 0;
    BOOL lastPosValid = NO;
    for (NSUInteger pos = 0; pos < strlen; ++pos) {
        // treat pos as the position of the final candidate character
        // expand it to include any compound grapheme points
        NSRange posRange = [string rangeOfComposedCharacterSequenceAtIndex:pos];
        pos = posRange.location + posRange.length - 1;

        // get the substring through the updated pos
        NSString *substr = [string substringToIndex:pos];
        len = [substr lengthOfBytesUsingEncoding:NSUTF8StringEncoding];
        if (len > utf8Bytes) {
            // this is the first substring that fails, so the previous one was
            // the substring that we want, so we can break
            break;
        }

        // this string still fit, so update the tracking vals
        lastPos = pos;
        lastPosValid = YES;
    }

    // if the last position was never valid, then only a zero length substr can fit
    if (! lastPosValid) {
        return [NSString string];
    } else {
        // otherwise, we want the substring through the last position
        return [string substringToIndex:lastPos];
    }
}

@end
