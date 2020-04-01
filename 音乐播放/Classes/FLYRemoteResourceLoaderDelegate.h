//
//  FLYRemoteResourceLoaderDelegate.h
//  音乐播放
//
//  Created by fly on 2020/3/25.
//  Copyright © 2020 fly. All rights reserved.
//

//全写在FLYRemotePlayer里会很乱，所以单独提出来写

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface FLYRemoteResourceLoaderDelegate : NSObject < AVAssetResourceLoaderDelegate >

@end

NS_ASSUME_NONNULL_END
