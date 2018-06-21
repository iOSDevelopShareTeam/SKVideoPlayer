//
//  SKSingleDownloader.m
//  SKVideoPlayer
//
//  Created by shavekevin on 2018/6/20.
//  Copyright © 2018年 shavekevin. All rights reserved.
//

#import "SKSingleDownloader.h"
#import <AFNetworking.h>

@interface SKSingleDownloader()

@property (strong, nonatomic) AFHTTPRequestSerializer *serializer;

@property (strong, nonatomic) AFURLSessionManager *downLoadSession;

@end

@implementation SKSingleDownloader

- (instancetype)initWithUrl:(NSString *)url filePath:(NSString *)filePath fileName:(NSString *)fileName duration:(NSInteger)duration index:(NSInteger)index {
    
    if (self = [super init]) {
        self.downLoadUrl = url;
        self.fileName = fileName;
        self.filePath = filePath;
        self.durtion = duration;
        self.index = index;
    }
    return self;
}

- (void)start {
    // 先检查一下之前有没有下载过
    if ([self checkCurrentTSFileDownload]) {
        //下载过
        if (self.delegate && [self.delegate respondsToSelector:@selector(singleTSFileDownLoadSuccess:)]) {
            [self.delegate singleTSFileDownLoadSuccess:self];
            return;
        }
    }
    
    // 拼接路径得到存储下载文件的路径
    __block NSString *path = [[[[NSSearchPathForDirectoriesInDomains(NSDocumentDirectory,NSUserDomainMask,YES) objectAtIndex:0] stringByAppendingPathComponent:@"Downloads"] stringByAppendingPathComponent:self.filePath] stringByAppendingPathComponent:self.fileName];
    //这里使用AFN下载,并将数据同时存储到沙盒目录制定的目录中
    NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:self.downLoadUrl]];
    __block NSProgress *progress = nil;
    NSURLSessionDownloadTask *downloadTask = [self.downLoadSession downloadTaskWithRequest:request progress:^(NSProgress * _Nonnull downloadProgress) {
        progress = downloadProgress;
        //添加对进度的监听
//        [progress addObserver:self forKeyPath:@"completedUnitCount" options:NSKeyValueObservingOptionNew context:nil];
        
    } destination:^NSURL * _Nonnull(NSURL * _Nonnull targetPath, NSURLResponse * _Nonnull response) {
        //
        //在这里告诉AFN数据存储的路径和文件名
        NSURL *documentsDirectoryURL = [NSURL fileURLWithPath:path isDirectory:NO];
        return documentsDirectoryURL;
    } completionHandler:^(NSURLResponse * _Nonnull response, NSURL * _Nullable filePath, NSError * _Nullable error) {
        if (error) {
            if (self.delegate && [self.delegate respondsToSelector:@selector(singleTSFileDownLoadFailed:)]) {
                [self.delegate singleTSFileDownLoadFailed:self];
            }
        }else {
            NSLog(@"路径%@保存成功", filePath);
            NSLog(@"下载成功");
            if (self.delegate && [self.delegate respondsToSelector:@selector(singleTSFileDownLoadSuccess:)]) {
                [self.delegate singleTSFileDownLoadSuccess:self];
            }
        }
//        [progress removeObserver:self forKeyPath:@"completedUnitCount"];
    }];
    
    //开始下载
    [downloadTask resume];
   
}
#pragma mark - 检查此文件是否下载过
- (BOOL)checkCurrentTSFileDownload {
    
    //获取缓存路径
    NSString *pathPrefix = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory,NSUserDomainMask,YES) objectAtIndex:0];
    // 这里路径根据自己需要来写不要像到demo里一样写死(写相对路径)
    NSString *savePath = [[pathPrefix stringByAppendingPathComponent:@"Downloads"] stringByAppendingPathComponent:self.filePath];
    NSFileManager *fileManager = [NSFileManager defaultManager];
    __block BOOL isExist = NO;
    //获取缓存路径下的所有的文件名
    NSArray *subFileArray = [fileManager subpathsAtPath:savePath];
    [subFileArray enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        //判断是否已经缓存了此文件
        if ([self.fileName isEqualToString:[NSString stringWithFormat:@"%@", obj]]) {
            //已经下载
            isExist = YES;
            *stop = YES;
        } else {
            //不存在
            isExist = NO;
        }
    }];
    return isExist;
}

#pragma mark - 监听进度
- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(NSProgress *)object change:(NSDictionary *)change context:(void *)context
{
    if ([keyPath isEqualToString:@"completedUnitCount"]) {
        if (self.delegate && [self.delegate respondsToSelector:@selector(singleTSFileDownLoad:TotalUnitCount:completedUnitCount:)]) {
            [self.delegate singleTSFileDownLoad:self TotalUnitCount:object.totalUnitCount completedUnitCount:object.completedUnitCount];
        }
    }
}

#pragma mark - init

- (AFHTTPRequestSerializer *)serializer {
    if (!_serializer) {
        _serializer = [AFHTTPRequestSerializer serializer];
    }
    return _serializer;
}

- (AFURLSessionManager *)downLoadSession {
    if (!_downLoadSession) {
        NSURLSessionConfiguration *configuration = [NSURLSessionConfiguration defaultSessionConfiguration];
        _downLoadSession = [[AFURLSessionManager alloc] initWithSessionConfiguration:configuration];
    }
    return _downLoadSession;
}

@end
