//
//  NSURL+SZ.h
//  音乐播放
//
//  Created by fly on 2020/3/27.
//  Copyright © 2020 fly. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface NSURL (SZ)

/**
 把URL的协议转换成sreaming协议
 (比如 http://xxxx 转换成 sreaming://xxxx)
 */
- (NSURL *)stramingURL;

/**
 把URL的协议转换成http协议
 */
- (NSURL *)httpURL;

@end

NS_ASSUME_NONNULL_END
