//
//  NSData+AES.h
//  Smile
//
//  Created by apple on 15/8/25.
//  Copyright (c) 2015年 Weconex. All rights reserved.
//

#import <Foundation/Foundation.h>

@class NSString;

@interface NSData (Encryption)
/*! @brief 加密(AES)
 */
- (NSData *)AES128EncryptWithKey:(NSString *)key
                             gIv:(NSString *)Iv;

/*! @brief 解密(AES)
 */
- (NSData *)AES128DecryptWithKey:(NSString *)key
                             gIv:(NSString *)Iv;

@end
