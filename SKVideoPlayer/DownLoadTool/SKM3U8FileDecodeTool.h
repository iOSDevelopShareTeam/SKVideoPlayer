//
//  SKM3U8FileDecodeTool.h
//  SKVideoPlayer
//
//  Created by shavekevin on 2018/6/20.
//  Copyright © 2018年 shavekevin. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

/**
 m3u8 解码的类 暴露在最外层 解析m3u8文件 交给其他工具进行处理
 */
@protocol SKM3U8FileDecodeToolDelegate <NSObject>

- (void)m3u8FileDecodeSuccess;

- (void)m3u8FileDecodeFail;

- (void)downLoadProgress:(CGFloat)progress;

@end
@interface SKM3U8FileDecodeTool : NSObject

- (void)decodeM3U8Url:(NSString *)url;

@property (nonatomic, weak) id<SKM3U8FileDecodeToolDelegate> delegate;

@property (nonatomic, strong) NSMutableArray *totalTSFileArray;
@end
