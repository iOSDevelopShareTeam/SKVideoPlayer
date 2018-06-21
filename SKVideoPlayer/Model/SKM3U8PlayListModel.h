//
//  SKM3U8PlayListModel.h
//  SKVideoPlayer
//
//  Created by shavekevin on 2018/6/19.
//  Copyright © 2018年 shavekevin. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface SKM3U8PlayListModel : NSObject


@property (nonatomic, copy) NSArray *tsFileArray;

/**
 唯一标识 建议使用视频资源的id
 */
@property (nonatomic, copy) NSString *uuid;

@property (nonatomic, assign,readonly) NSInteger length;

@end
