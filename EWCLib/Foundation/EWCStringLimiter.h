//
//  EWCStringLimiter.h
//  Screencast
//
//  Created by Ansel Rognlie on 2018/02/08.
//  Copyright © 2018 Ansel Rognlie. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface EWCStringLimiter : NSObject

+ (NSString *)cutString:(NSString *)string toFitBytes:(int)utf8Bytes;

@end
