//
//  EWCPair.h
//  Screencast
//
//  Created by Ansel Rognlie on 2018/02/06.
//  Copyright © 2018 Ansel Rognlie. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface EWCPair<__covariant FirstType, __covariant SecondType> : NSObject

+ (instancetype)pairWithFirst:(FirstType)first second:(SecondType)second;

- (instancetype)initWithFirst:(FirstType)first second:(SecondType)second;

@property FirstType first;
@property SecondType second;

@end
