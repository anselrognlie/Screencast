//
//  EWCCFTypeRef.c
//  Screencast
//
//  Created by Ansel Rognlie on 2018/02/02.
//  Copyright © 2018 Ansel Rognlie. All rights reserved.
//

#include "EWCCFTypeRef.h"

#import <CoreFoundation/CoreFoundation.h>

void EWCSwapCFTypeRef(void *old, void *new) {
    CFTypeRef *oldRefPtr = (CFTypeRef *)old;
    CFTypeRef *newRefPtr = (CFTypeRef *)new;
    
    if (*newRefPtr) {
        CFRetain(*newRefPtr);
    }
    
    if (*oldRefPtr) {
        CFRelease(*oldRefPtr);
    }
    
    *oldRefPtr = *newRefPtr;
}
