//
//  EWCDataHelper.h
//  Screencast
//
//  Created by Ansel Rognlie on 2018/02/08.
//  Copyright © 2018 Ansel Rognlie. All rights reserved.
//

#ifndef EWCDataHelper_h
#define EWCDataHelper_h

#define EWC_UPDATE_CHECKSUM_LEN(checksum, value, len) \
do { \
    uint8_t *EWC_UPDATE_CHECKSUM##data = (uint8_t *)&(value); \
    for (int i = 0; i < (len); ++i) { \
        (checksum) += *(EWC_UPDATE_CHECKSUM##data++); \
    } \
} while (0) \

#define EWC_UPDATE_CHECKSUM(checksum, value) \
EWC_UPDATE_CHECKSUM_LEN((checksum), (value), sizeof(value)) \

#define EWC_UPDATE_SIZE(size, type, field) \
do { \
    (size) += sizeof(((type *)0)->field); \
} while (0) \

#define EWC_APPEND_DATA_LEN(nsdata, value, len) \
do { \
    [(nsdata) appendBytes:&(value) length:(len)]; \
} while (0) \

#define EWC_APPEND_DATA(nsdata, value) \
EWC_APPEND_DATA_LEN((nsdata), (value), sizeof(value))

#define EWC_EXTRACT_BEGIN \
do { \
    NSUInteger EWC_EXTRACT_BEGINoffset = 0; \

#define EWC_EXTRACT_DATA_LEN(value, nsdata, len) \
do { \
    [(nsdata) getBytes:&(value) range:NSMakeRange(EWC_EXTRACT_BEGINoffset, (len))]; \
    EWC_EXTRACT_BEGINoffset += (len); \
} while (0) \

#define EWC_EXTRACT_DATA(value, nsdata) \
EWC_EXTRACT_DATA_LEN(value, nsdata, sizeof(value)) \

#define EWC_EXTRACT_END \
} while (0);

#endif /* EWCDataHelper_h */
