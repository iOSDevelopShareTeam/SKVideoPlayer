//
//  SKVideoDownloader.m
//  SKVideoPlayer
//
//  Created by shavekevin on 2018/6/20.
//  Copyright © 2018年 shavekevin. All rights reserved.
//

#import "SKVideoDownloader.h"
#import "SKSingleDownloader.h"
#import "SKSingleDownLoadModel.h"


@interface SKVideoDownloader  ()<SKSingleTSFileDownLoadDelegate>

//记录一共多少TS文件
@property (assign, nonatomic) NSInteger index;
//记录所有的下载链接
@property (strong, nonatomic) NSMutableArray *downloadUrlArray;
//记录下载成功的文件的数量（以3为基数）
@property (assign, nonatomic) NSInteger successDownloadCount;

@end

@implementation SKVideoDownloader

- (instancetype)init {
    if (self = [super init]) {
        self.index = 0;
        self.successDownloadCount = 1;
    }
    return self;
}

- (void)startDownLoadVideo {
    // 先检查路径
    [self checkDirectoryIsCreateM3U8];
    __weak __typeof(self)weakSelf = self;
    //将解析的数据打包成一个个独立的下载器装进数组
    [self.playList.tsFileArray enumerateObjectsUsingBlock:^(SKSingleDownLoadModel *obj, NSUInteger idx, BOOL * _Nonnull stop) {
        //检查此下载对象是否存在
        __block BOOL isExist = NO;
        [weakSelf.downloadUrlArray enumerateObjectsUsingBlock:^(NSString *inObj, NSUInteger inIdx, BOOL * _Nonnull inStop) {
            if ([inObj isEqualToString:obj.locationUrl]) {
                //已经存在
                isExist = YES;
                *inStop = YES;
            } else {
                //不存在
                isExist = NO;
            }
        }];
        
        if (isExist) {
            //存在
        } else {
            //不存在
            NSString *fileName = [NSString stringWithFormat:@"videoid-%ld.ts", (long)weakSelf.index];
            
            SKSingleDownloader *sgDownloader = [[SKSingleDownloader alloc]initWithUrl:[@"https://vpro01.allinmd.cn" stringByAppendingString:obj.locationUrl] filePath:weakSelf.playList.uuid fileName:fileName duration:obj.duration index:weakSelf.index];
            sgDownloader.delegate = weakSelf;
            NSLog(@"下载的地址为：https://vpro01.allinmd.cn%@",obj.locationUrl);
            [weakSelf.downloadArray addObject:sgDownloader];
            [weakSelf.downloadUrlArray addObject:obj.locationUrl];
            weakSelf.index++;
        }
        
    }];
    //根据新的数据更改新的playList
    __block NSMutableArray *newPlaylistArray = [[NSMutableArray alloc] init];
    [self.downloadArray enumerateObjectsUsingBlock:^(SKSingleDownloader *obj, NSUInteger idx, BOOL * _Nonnull stop) {
        SKSingleDownLoadModel *model = [[SKSingleDownLoadModel alloc] init];
        model.duration = obj.durtion;
        model.locationUrl = obj.fileName;
        model.index = obj.index;
        [newPlaylistArray addObject:model];
    }];
    
    if (newPlaylistArray.count > 0) {
        self.playList.tsFileArray = newPlaylistArray;
    }
    
    //打包完成开始下载
    [self.downloadArray enumerateObjectsUsingBlock:^(SKSingleDownloader *obj, NSUInteger idx, BOOL * _Nonnull stop) {
        obj.flag = YES;
        [obj start];
    }];
    
}
#pragma mark - 检查路径
- (void)checkDirectoryIsCreateM3U8{
    //创建缓存路径
    NSString *pathPrefix = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory,NSUserDomainMask,YES) objectAtIndex:0];
    NSString *savePath = [[pathPrefix stringByAppendingPathComponent:@"Downloads"] stringByAppendingPathComponent:self.playList.uuid];
    NSFileManager *fileManager = [NSFileManager defaultManager];
    //路径不存在就创建一个
    if (![fileManager fileExistsAtPath:savePath]) {
        //不存在 create
        BOOL createSuccess = [fileManager createDirectoryAtPath:savePath withIntermediateDirectories:YES attributes:nil error:nil];
        if (createSuccess) {
            NSLog(@"路径不存在创建成功");
        } else {
            NSLog(@"路径不存在创建失败");
        }
    }
}

- (void)singleTSFileDownLoad:(SKSingleDownloader *)downloader TotalUnitCount:(int64_t)totalUnitCount completedUnitCount:(int64_t)completedUnitCount {
//    NSLog(@"下载进度：%f", completedUnitCount * 1.0 / totalUnitCount * 1.0);
}

- (void)singleTSFileDownLoadFailed:(SKSingleDownloader *)downloader {
    if (self.delegate && [self.delegate respondsToSelector:@selector(videoDownLoadFailed:)]) {
        [self.delegate videoDownLoadFailed:self];
        NSLog(@"下载器下载文件失败");
    }
}

- (void)singleTSFileDownLoadSuccess:(SKSingleDownloader *)downloader {
    //数据下载成功后再数据源中移除当前下载器
    //应该是如果下载完了 就清除下载器
    NSLog(@"self.successDownloadCount=====%@,self.playList.segmentArray===%@",@(self.successDownloadCount),@(self.playList.tsFileArray.count));
    NSLog(@"下载器下载了%ld个文件",self.successDownloadCount);
    CGFloat downloadProgress = (CGFloat)self.successDownloadCount/self.playList.tsFileArray.count;
    if (self.delegate &&[self.delegate respondsToSelector:@selector(videoDownLoadProgress:)]) {
        [self.delegate videoDownLoadProgress:downloadProgress];
    }
    if (self.successDownloadCount > self.playList.tsFileArray.count) {
        return;
    }

    if (self.successDownloadCount >= 3) {
        if (self.delegate && [self.delegate respondsToSelector:@selector(videoDownLoadSuccess:)]) {
//            if (self.successDownloadCount == self.playList.tsFileArray.count) {
//                [self createLocalM3U8File];
//            }
            [self createLocalM3U8File];

            [self.delegate videoDownLoadSuccess:self];
        }
    }
    self.successDownloadCount++;




}

/**
 注意：每个公司的m3u8文件结构可能不同，这里不要按照demo给出的来写，根据实际情况来写(这个方法是重组本地.ts文件 组成本地m3u8文件然后播放)
 */
- (void)createLocalM3U8File {
    
    [self checkDirectoryIsCreateM3U8];
    //创建M3U8的链接地址
    NSString *path = [[[[NSSearchPathForDirectoriesInDomains(NSDocumentDirectory,NSUserDomainMask,YES) objectAtIndex:0] stringByAppendingPathComponent:@"Downloads"] stringByAppendingPathComponent:self.playList.uuid] stringByAppendingPathComponent:@"movie.m3u8"];
    
    //拼接M3U8链接的头部具体内容
    NSString *header = [NSString stringWithFormat:@"#EXTM3U\n#EXT-X-VERSION:3\n#EXT-X-MEDIA-SEQUENCE:0\n#EXT-X-TARGETDURATION:69\n"];
    //填充M3U8数据
    __block NSString *tsStr = [[NSString alloc] init];
    [self.playList.tsFileArray enumerateObjectsUsingBlock:^(SKSingleDownLoadModel *obj, NSUInteger idx, BOOL * _Nonnull stop) {
        //文件名
        NSString *fileName = [NSString stringWithFormat:@"videoid-%ld.ts", obj.index];
        //文件时长
        NSString* length = [NSString stringWithFormat:@"#EXTINF:%ld,\n",obj.duration];
        //拼接M3U8
        tsStr = [tsStr stringByAppendingString:[NSString stringWithFormat:@"%@%@\n", length, fileName]];
    }];
    //M3U8头部和中间拼接,到此我们完成的新的M3U8链接的拼接
    header = [header stringByAppendingString:tsStr];
    header = [header stringByAppendingString:@"#EXT-X-ENDLIST"];
    //拼接完成，存储到本地
    NSMutableData *writer = [[NSMutableData alloc] init];
    NSFileManager *fileManager = [NSFileManager defaultManager];
    //判断m3u8是否存在,已经存在的话就不再重新创建
    if (![fileManager fileExistsAtPath:path isDirectory:nil]) {
        //不存在这个链接
        NSString *saveTo = [[[NSSearchPathForDirectoriesInDomains(NSDocumentDirectory,NSUserDomainMask,YES) objectAtIndex:0] stringByAppendingPathComponent:@"Downloads"] stringByAppendingPathComponent:self.playList.uuid];
        BOOL isS = [fileManager createDirectoryAtPath:saveTo withIntermediateDirectories:YES attributes:nil error:nil];
        if (isS) {
            NSLog(@"创建目录成功");
        } else {
            NSLog(@"创建目录失败");
        }
    }else {
        NSLog(@"存在这个链接");
    }
    [writer appendData:[header dataUsingEncoding:NSUTF8StringEncoding]];
    BOOL writeSuccess = [writer writeToFile:path atomically:YES];
    if (writeSuccess) {
        //成功
        NSLog(@"M3U8数据保存成功");
    } else {
        //失败
        NSLog(@"M3U8数据保存失败");
    }
    NSLog(@"新数据\n%@", header);
}

#pragma mark - getter
- (NSMutableArray *)downloadArray {
    if (!_downloadArray) {
        _downloadArray = [[NSMutableArray alloc] init];
    }
    return _downloadArray;
}

- (NSMutableArray *)downloadUrlArray {
    if (!_downloadUrlArray) {
        _downloadUrlArray = [[NSMutableArray alloc] init];
    }
    return _downloadUrlArray;
}
@end
