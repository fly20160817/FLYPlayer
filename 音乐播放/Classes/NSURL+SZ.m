//
//  NSURL+SZ.m
//  音乐播放
//
//  Created by fly on 2020/3/27.
//  Copyright © 2020 fly. All rights reserved.
//

#import "NSURL+SZ.h"

@implementation NSURL (SZ)

- (NSURL *)stramingURL
{
    NSURLComponents * components = [NSURLComponents componentsWithString:self.absoluteString];
    
    components.scheme = @"sreaming";
    
    return components.URL;
}

- (NSURL *)httpURL
{
    NSURLComponents * components = [NSURLComponents componentsWithString:self.absoluteString];
    
    components.scheme = @"http";
    
    return components.URL;
}

@end
