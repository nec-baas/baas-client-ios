//
//  NBURLSession.m
//
//  COPYRIGHT (C) 2014 NEC CORPORATION
//


#import "NBURLSession.h"
#import "NBUploadDelegate.h"
#import "NBDownloadDelegate.h"
#import "NBUtilities.h"
#import "NBErrorFactory.h"
#import "Common.h"

/**
 *  インスタンス変数
 */
@interface NBURLSession ()
@property (nonatomic) NSURLSessionConfiguration *sessionConfiguration;
@property (nonatomic) NSURLSessionConfiguration *sessionConfigurationDownload;
@property (nonatomic) NSURLSessionConfiguration *sessionConfigurationUpload;

@property (nonatomic) NSURLSession *session;
@property (nonatomic) NSURLSession *sessionDownload;
@property (nonatomic) NSURLSession *sessionUpload;

@end

@implementation NBURLSession

/**
 *  定数
 */
static NSString * const NBParentFolderName = @"/Nebula";

#pragma mark - public methods

// Background Session ID
static NSString * const NBDownloadSessionID = @"nebulaIosSdkDownloadSessionIdentifier";
static NSString * const NBUploadSessionID = @"nebulaIosSdkUploadSessionIdentifier";

+ (instancetype)sharedInstance {
    // 本クラスはライブラリ内でのみ使用されるため、allocWithZoneとcopyWithZoneのオーバーライドは省略する

    static id _sharedInstance = nil;
    static dispatch_once_t oncePredicate;
    dispatch_once(&oncePredicate, ^{
        _sharedInstance = [[self alloc] init];
    });

    return _sharedInstance;
}

- (void)dataTaskWithRequest:(NSURLRequest *)request block:(NBURLSessionBlock)block {
    // Blocks保持
    NBURLSessionBlock copyBlock = [block copy];

    // DataTask生成
    DLog(@"dataTaskWithRequest");
    NSURLSessionDataTask * dataTask = [self.session dataTaskWithRequest:request
                                       completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {

                                           if (copyBlock) {
                                               // コールバックのBlocksに設定
                                               copyBlock(data, response, error);
                                           }

                                       }];

    // Task実行（通信開始）
    [dataTask resume];
}

- (void)downloadTaskWithRequest:(NSURLRequest *)request toURL:(NSURL *)fileURL block:(NBURLSessionDownloadBlock)block progressBlock:(
        NBURLSessionProgressBlock)progressBlock {
    // DownloadTask生成
    DLog(@"downloadTaskWithRequest");
    NSURLSessionDownloadTask * downloadTask = [self.sessionDownload downloadTaskWithRequest:request];
    DLog(@"downloadTask: %lu", (unsigned long)downloadTask.taskIdentifier);

    // Blocks保持
    NBDownloadDelegate *delegate = (NBDownloadDelegate *)self.sessionDownload.delegate;
    // task IDが確定した時点でそのtask ID用の領域を確保する
    if (!delegate.downloadParams[@(downloadTask.taskIdentifier)]) {
        delegate.downloadParams[@(downloadTask.taskIdentifier)] = [NSMutableDictionary dictionary];
    }
    delegate.downloadParams[@(downloadTask.taskIdentifier)][NBKeyBlock] = [block copy];
    delegate.downloadParams[@(downloadTask.taskIdentifier)][NBKeyProgressBlock] = [progressBlock copy];

    // FileURL保持
    if (fileURL) {
        delegate.downloadParams[@(downloadTask.taskIdentifier)][NBKeyDownloadDestination] = fileURL;
    }

    // Task実行（通信開始）
    [downloadTask resume];
}

- (void)uploadTaskWithRequest:(NSURLRequest *)request fromFile:(NSURL *)fileURL block:(NBURLSessionBlock)block progressBlock:(
        NBURLSessionProgressBlock)progressBlock {
    // UploadTask生成
    DLog(@"uploadTaskWithRequest");
    NSURLSessionUploadTask * uploadTask = [self.sessionUpload uploadTaskWithRequest:request fromFile:fileURL];
    DLog(@"uploadTask: %lu", (unsigned long)uploadTask.taskIdentifier);

    // taskDescriptionに一時ファイル名を保存する
    uploadTask.taskDescription = fileURL.absoluteString;
    DLog(@"taskDescription: %@", fileURL.absoluteString);

    // Blocks保持
    NBUploadDelegate *delegate = (NBUploadDelegate *)self.sessionUpload.delegate;
    // task IDが確定した時点でそのtask ID用の領域を確保する
    if (!delegate.uploadParams[@(uploadTask.taskIdentifier)]) {
        delegate.uploadParams[@(uploadTask.taskIdentifier)] = [NSMutableDictionary dictionary];
    }
    delegate.uploadParams[@(uploadTask.taskIdentifier)][NBKeyBlock] = [block copy];
    delegate.uploadParams[@(uploadTask.taskIdentifier)][NBKeyProgressBlock] = [progressBlock copy];

    // Task実行（通信開始）
    [uploadTask resume];
}

- (void)recreateSessionWithIdentifier:(NSString *)identifier completionHandler:(void (^)(void))completionHandler {
    DLog(@"recreateSessionWithIdentifier: %@", identifier);
    DLog(@"recreateSessionWithIdentifier: %@", completionHandler);

    if ([identifier isEqualToString:NBDownloadSessionID]) {
        [self createDownloadSession];
        NBDownloadDelegate *delegate = (NBDownloadDelegate *)self.sessionDownload.delegate;
        delegate.downloadParams[NBKeyCompletionHandler] = [completionHandler copy];
    } else if ([identifier isEqualToString:NBUploadSessionID]) {
        [self createUploadSession];
        NBUploadDelegate *delegate = (NBUploadDelegate *)self.sessionUpload.delegate;
        delegate.uploadParams[NBKeyCompletionHandler] = [completionHandler copy];
    }
}

- (void)createDataSession {
    if (!self.session) {
        self.sessionConfiguration = [NSURLSessionConfiguration defaultSessionConfiguration];
        self.session = [NSURLSession sessionWithConfiguration:self.sessionConfiguration];
    }
}

- (void)createDownloadSession {
    if (!self.sessionDownload) {
        self.sessionConfigurationDownload = [NSURLSessionConfiguration backgroundSessionConfigurationWithIdentifier:NBDownloadSessionID];
        NBDownloadDelegate *downloadDelegate = [NBDownloadDelegate new];
        self.sessionDownload = [NSURLSession sessionWithConfiguration:self.sessionConfigurationDownload delegate:downloadDelegate delegateQueue:nil];
    }
}

- (void)createUploadSession {
    if (!self.sessionUpload) {
        self.sessionConfigurationUpload = [NSURLSessionConfiguration backgroundSessionConfigurationWithIdentifier:NBUploadSessionID];
        NBUploadDelegate *uploadDelegate = [NBUploadDelegate new];
        self.sessionUpload = [NSURLSession sessionWithConfiguration:self.sessionConfigurationUpload delegate:uploadDelegate delegateQueue:nil];
    }
}

+ (NSURL *)createTemporaryFileWithData:(NSData *)data error:(NSError **)error {
    BOOL result = YES;

    NSString *tempPath = [NSTemporaryDirectory() stringByAppendingPathComponent:NBParentFolderName];
    NSFileManager *fm = [NSFileManager defaultManager];
    if (![fm fileExistsAtPath:tempPath]) {
        @synchronized(self) {
            // Nebulaフォルダがなければ、作成する
            result = [fm createDirectoryAtPath:tempPath withIntermediateDirectories:YES attributes:nil error:error];
        }
    }

    if (!result) {
        DLog(@"failed to create directory: %@", *error);
        return nil;
    }

    NSString *tempFile =
        [[tempPath stringByAppendingPathComponent:[NSProcessInfo processInfo].globallyUniqueString] stringByAppendingPathExtension:@"tmp"];
    DLog(@"tempFile: %@", tempFile);
    @synchronized(self) {
        // writeToFileは公開ディレクトリで使用するのは非推奨だが、基本的には本ライブラリしかアクセスしないディレクトリなので問題なしとする
        result = [data writeToFile:tempFile atomically:YES];
    }

    if (!result) {
        *error = [NBErrorFactory makeErrorForCode:NBErrorRequestError];
        return nil;
    }

    return [NSURL fileURLWithPath:tempFile];
}

+ (void)removeTemporaryFileWithURL:(NSURL *)fileURL error:(NSError **)error {
    NSString *tempFilePath = fileURL.path;
    NSString *tempPath = [NSTemporaryDirectory() stringByAppendingPathComponent:NBParentFolderName];
    NSRange range = [tempFilePath rangeOfString:tempPath];
    if (range.length != 0 && range.location == 0) {
        @synchronized(self) {
            DLog(@"remove temporary file: %@", tempFilePath);
            [[NSFileManager defaultManager] removeItemAtPath:tempFilePath error:error];
        }
    }
}

- (instancetype)init {
    self = [super init];

    if (self) {
        // セッション設定
        self.sessionConfiguration = nil;
        self.sessionConfigurationDownload = nil;
        self.sessionConfigurationUpload = nil;

        // セッション
        self.session = nil;
        self.sessionDownload = nil;
        self.sessionUpload = nil;
    }

    return self;
}

@end
