//
//  NBRestExecutor.m
//
//  COPYRIGHT (C) 2014 NEC CORPORATION
//


#import "NBRestExecutor.h"
#import "NBURLSession.h"
#import "NBErrorFactory.h"
#import "NBLog.h"
#import "Common.h"

@interface NBRestExecutor ()

@property (nonatomic) NSString *requestName;
/**
 *  handle http request
 */
@property (nonatomic) NSURLRequest *request;

@end

@implementation NBRestExecutor

static const NSInteger NBStatusCodeSuccess = 200;
static NSString *const NBHeaderXContentLength = @"X-Content-Length";

@synthesize requestName;
@synthesize request;

#pragma mark - public methods

+ (NBRestExecutor *)executorWithRequest:(NSURLRequest *)urlRequest name:(NSString *)name {
    NBRestExecutor *instance = [[NBRestExecutor alloc] init];
    instance.requestName = name;
    instance.request = urlRequest;

    return instance;
}

- (void)executeRequestInBackgroundWithBlock:(NBResponseBlock)block {
    // 非同期の応答時に使うため、callbackを保持しておく
    NBResponseBlock copyBlock = [block copy];

    // 非同期スレッドでの通信実行
    dispatch_queue_t globalQueue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
    dispatch_async(
        globalQueue,
        ^{
        // 要求元情報出力(正常系)
        DLog(@"Executor Request : %@", self.requestName);
        // 共通リクエストログ出力
        [NBLog logURLRequest:self.request];

        // Request実行
        NBURLSession *urlSession = [NBURLSession sharedInstance];
        [urlSession createDataSession];
        [urlSession dataTaskWithRequest:self.request block:^(NSData *data, NSURLResponse *response, NSError *error) {
             // 要求元情報出力(正常系)
             DLog(@"Executor Response : %@", self.requestName);
             // 共通レスポンスログ出力
             [NBLog logURLResponse:response body:data error:error];

             // responseとerrorの併せ込み
             // 通信を行い、ResponseCodeが成功でなければErrorを生成する(サーバからのエラーを優先する)
             NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)response;
             NSInteger code = [httpResponse statusCode];
             // responseがnilの場合は除外する(ステータスコードが0になってしまいif文の中に入ってしまうのを防ぐ)
             if (response && code != NBStatusCodeSuccess) {
                 error = [NBErrorFactory makeErrorForCode:code withResponseBody:data];
             }

             // Main Threadでの応答
             dispatch_async(dispatch_get_main_queue(), ^{
                copyBlock(data, error);
            });
         }];
    });
}

- (void)executeDownloadRequestInBackgroundWithURL:(NSURL *)fileURL block:(NBResponseDownloadBlock)block progressBlock:(
        NBResponseProgressBlock)progressBlock {
    // 非同期の応答時に使うため、callbackを保持しておく
    NBResponseDownloadBlock copyBlock = [block copy];
    NBResponseProgressBlock copyProgressBlock = [progressBlock copy];

    // 非同期スレッドでの通信実行
    dispatch_queue_t globalQueue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
    dispatch_async(
        globalQueue,
        ^{
        // 要求元情報出力(正常系)
        DLog(@"Executor Request : %@", self.requestName);
        // 共通リクエストログ出力
        [NBLog logURLRequest:self.request];

        // Request実行
        NBURLSession *urlSession = [NBURLSession sharedInstance];
        [urlSession createDownloadSession];
        [urlSession downloadTaskWithRequest:self.request toURL:fileURL block:^(NSURL *url, NSData *data, NSURLResponse *response, NSError *error) {
             // 要求元情報出力(正常系)
             DLog(@"Executor Response : %@", self.requestName);
             // 共通レスポンスログ出力
             [NBLog logURLResponse:response body:[[url absoluteString] dataUsingEncoding:NSUTF8StringEncoding] error:error];

             // responseとerrorの併せ込み
             // 通信を行い、ResponseCodeが成功でなければErrorを生成する(サーバからのエラーを優先する)
             NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)response;
             NSInteger code = [httpResponse statusCode];
             // responseがnilの場合は除外する(ステータスコードが0になってしまいif文の中に入ってしまうのを防ぐ)
             if (response && code != NBStatusCodeSuccess) {
                 error = [NBErrorFactory makeErrorForCode:code withResponseBody:data];
             }
             // 200 OK
             else if (!error) {
                 // 途中で異常終了している可能性があるので、ファイルサイズを確認
                 DLog(@"url.path: %@", url.path);
                 NSDictionary *attr = [[NSFileManager defaultManager] attributesOfItemAtPath:url.path error:&error];
                 DLog(@"error[RestExecutor]: %@", error);

                 if (!error) {
                     // X-Content-Length値を取得
                     NSDictionary *allHeaders = httpResponse.allHeaderFields;
                     long long xContentLength = 0;
                     if (allHeaders && [allHeaders.allKeys containsObject:NBHeaderXContentLength]) {
                         xContentLength = [allHeaders[NBHeaderXContentLength] longLongValue];
                     } else {
                         error = [NBErrorFactory makeErrorForCode:NBErrorFailedToDownload];
                     }

                     // ダウンロードされたファイルサイズを取得
                     // 同じerrorなので、ここでerrorチェックはしない
                     long long downloadedSize = 0;
                     if (attr && [attr.allKeys containsObject:NSFileSize]) {
                         downloadedSize = [attr[NSFileSize] longLongValue];
                     } else {
                         error = [NBErrorFactory makeErrorForCode:NBErrorFailedToDownload];
                     }

                     DLog(@"xContentLength: %lld", xContentLength);
                     DLog(@"downloadedSize: %lld", downloadedSize);

                     // X-Content-Lengthとダウンロードされたファイルサイズを比較し、一致しない場合はerrorとする
                     if (!error && xContentLength != downloadedSize) {
                         error = [NBErrorFactory makeErrorForCode:NBErrorFailedToDownload];
                     }
                 }
                 if (error) {
                     // 中断されたダウンロードファイルを削除する
                     // ファイル削除に失敗した場合はerrorは書きかわる（そのためにファイル存在チェックを行う）
                     if ([[NSFileManager defaultManager] fileExistsAtPath:url.path]) {
                         [[NSFileManager defaultManager] removeItemAtPath:url.path error:&error];
                     }
                     // errorが発生していたらurlをnilにする
                     url = nil;
                 }
             }

             // Main Threadでの応答
             dispatch_async(dispatch_get_main_queue(), ^{
                copyBlock(url, error);
            });
         }
         progressBlock:^(int64_t trasferred, int64_t expected) {
             copyProgressBlock(trasferred, expected);
         }];
    });
}

- (void)executeUploadRequestInBackgroundWithURL:(NSURL *)fileURL block:(NBResponseBlock)block progressBlock:(NBResponseProgressBlock)
    progressBlock {
    // 非同期の応答時に使うため、callbackを保持しておく
    NBResponseBlock copyBlock = [block copy];
    NBResponseProgressBlock copyProgressBlock = [progressBlock copy];

    // 非同期スレッドでの通信実行
    dispatch_queue_t globalQueue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
    dispatch_async(
        globalQueue,
        ^{
        // 要求元情報出力(正常系)
        DLog(@"Executor Request : %@", self.requestName);

        // 共通リクエストログ出力
        [NBLog logURLRequest:self.request];

        // Request実行
        NBURLSession *urlSession = [NBURLSession sharedInstance];
        [urlSession createUploadSession];
        [urlSession uploadTaskWithRequest:self.request fromFile:fileURL block:^(NSData *data, NSURLResponse *response, NSError *error) {
             // 要求元情報出力(正常系)
             DLog(@"Executor Response : %@", self.requestName);
             // 共通レスポンスログ出力
             [NBLog logURLResponse:response body:data error:error];

             // responseとerrorの併せ込み
             // 通信を行い、ResponseCodeが成功でなければErrorを生成する(サーバからのエラーを優先する)
             NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)response;
             NSInteger code = [httpResponse statusCode];
             // responseがnilの場合は除外する(ステータスコードが0になってしまいif文の中に入ってしまうのを防ぐ)
             if (response && code != NBStatusCodeSuccess) {
                 error = [NBErrorFactory makeErrorForCode:code withResponseBody:data];
             }

             // Main Threadでの応答
             dispatch_async(dispatch_get_main_queue(), ^{
                copyBlock(data, error);
            });
         }
         progressBlock:^(int64_t trasferred, int64_t expected) {
             copyProgressBlock(trasferred, expected);
         }];
    });
}

@end

