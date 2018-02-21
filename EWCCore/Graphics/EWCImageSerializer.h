//
//  EWCImageSerializer.h
//  EWCCore
//
//  Created by Ansel Rognlie on 2018/02/21.
//  Copyright © 2018 Ansel Rognlie. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface EWCImageSerializer : NSObject

+ (NSData *)createPngFromImage:(CGImageRef)image;

+ (NSData *)serializeImage:(CGImageRef)image asType:(NSString *)type;

@end
