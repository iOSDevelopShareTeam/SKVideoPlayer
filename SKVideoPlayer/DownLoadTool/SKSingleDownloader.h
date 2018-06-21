//
//  SKSingleDownloader.h
//  SKVideoPlayer
//
//  Created by shavekevin on 2018/6/20.
//  Copyright © 2018年 shavekevin. All rights reserved.
//
// 单个ts文件下载器

#import <Foundation/Foundation.h>

@class SKSingleDownloader;
@protocol SKSingleTSFileDownLoadDelegate<NSObject>

/**
 file download success

 @param downloader single ts file download
 */
- (void)singleTSFileDownLoadSuccess:(SKSingleDownloader *)downloader;

/**
 file download success
 
 @param downloader single ts file download
 */
- (void)singleTSFileDownLoadFailed:(SKSingleDownloader *)downloader;

/**
 download progress

 @param downloader downloader
 @param totalUnitCount total
 @param completedUnitCount download
 */
- (void)singleTSFileDownLoad:(SKSingleDownloader *)downloader TotalUnitCount:(int64_t)totalUnitCount completedUnitCount:(int64_t)completedUnitCount;

@end

@interface SKSingleDownloader : NSObject

/**
 target fileName
 */
@property (nonatomic, copy) NSString *fileName;

/**
 destination filePath
 */
@property (nonatomic, copy) NSString *filePath;

/**
 downLoadUrl
 */
@property (nonatomic, copy) NSString *downLoadUrl;
/**
 file durtion
 */
@property (nonatomic, assign) NSInteger durtion;
/**
 download current index
 */
@property (nonatomic, assign) NSInteger index;

/**
 cueent downloader downloading or not
 */
@property (nonatomic, assign) BOOL flag;


/**
 init

 @param url download url
 @param filePath downloadPath
 @param fileName downloadFileName
 @param duration file duration
 @param index download index
 @return downloader self
 */
- (instancetype)initWithUrl:(NSString *)url filePath:(NSString *)filePath fileName:(NSString *)fileName duration:(NSInteger)duration index:(NSInteger)index;

/**
 download status delegate
 */
@property (nonatomic, weak) id <SKSingleTSFileDownLoadDelegate> delegate;

/**
 start download
 */
- (void)start;

/**
 stop download
 */
- (void)stop;

/**
 pause download
 */
- (void)pause;

@end
