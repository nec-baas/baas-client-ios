//
//  NBDownloadDelegate.m
//
//  COPYRIGHT (C) 2014 NEC CORPORATION
//


#import "NBDownloadDelegate.h"
#import "NBUtilities.h"
#import "Common.h"

@implementation NBDownloadDelegate

static NSString *const NBHeaderContentLength = @"X-Content-Length";

/**
 *  downloadParams用のキー
 *  ダウンロード完了後に実際に保存されたファイルURL
 */
static NSString *const NBKeyDownloadFileURL = @"downloadFileURL";

/**
 *  downloadParams用のキー
 *  ダウンロード完了後のテンポラリファイル移動時に発生したエラー内容
 */
static NSString *const NBKeyDownloadMoveError = @"downloadMoveError";

/**
 *  HttpResponseのSuccessCode
 *  ダウンロードの成否判定に使用
 */
static const NSInteger NBStatusCodeSuccess = 200;

/**
 *  HttpResponse失敗時に設定するResponseBodyの文字列
 */
static NSString *const NBJsonStringFileDownloadFailed = @"{\"error\":\"Download failed\"}";

- (instancetype)init {
    self = [super init];

    if (self) {
        self.downloadParams = [NSMutableDictionary dictionary];
    }

    return self;
}


#pragma mark - NSURLSessionDelegate

- (void)URLSessionDidFinishEventsForBackgroundURLSession:(NSURLSession *)session {
    DLog(@"URLSessionDidFinishEventsForBackgroundURLSession: %@", session.configuration.identifier);
    // NSURLSessionDownloadTaskのdelegate実行後に呼ばれる
    // ここでOSに完了を通知

    DLog(@"Background URL session %@ finished events.", session);

    void (^completionHandler)(void) = self.downloadParams[NBKeyCompletionHandler];
    if (completionHandler) {
        [self.downloadParams removeObjectForKey:NBKeyCompletionHandler];
        completionHandler();
    } else {
        DLog(@"completionHandler not set");
    }
}


#pragma - NSURLSessionTaskDelegate

// Tells the delegate that the task finished transferring data.
- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task didCompleteWithError:(NSError *)error {
    DLog(@"[didCompleteWithError]task: %lu", (unsigned long)task.taskIdentifier);
    DLog(@"didCompleteWithError: error: %@", error);

    DLog(@"downloadParams: %@", self.downloadParams);

    // 転送エラーがなかった場合は、ファイル移動のエラーがなかったか確認する
    if (!error) {
        error = self.downloadParams[@(task.taskIdentifier)][NBKeyDownloadMoveError];
    }

    // ダウンロードしたファイルの保存先パスを取得する(失敗している場合は該当のキーがないのでnilになる)
    NSURL *downloadFileURL = self.downloadParams[@(task.taskIdentifier)][NBKeyDownloadFileURL];

    // サーバーの応答が失敗の場合のResponseBodyを取得
    NSData *errorResponseBody = nil;
    // サーバーから応答あり
    if(task.response) {
        NSInteger statusCode = ((NSHTTPURLResponse *)task.response).statusCode;
        // 200 OK以外のメッセージを受信した場合
        if(statusCode != NBStatusCodeSuccess) {
            // サーバからのエラーメッセージを受信できないため、代替のテキストを格納
            errorResponseBody = [NBJsonStringFileDownloadFailed dataUsingEncoding:NSUTF8StringEncoding];
        }
    }

    // 完了報告用のBlockをコールする
    NBURLSessionDownloadBlock downloadBlock = self.downloadParams[@(task.taskIdentifier)][NBKeyBlock];
    if (downloadBlock) {
        downloadBlock(downloadFileURL, errorResponseBody, task.response, error);
    } else {
        DLog(@"downloadBlock not set");
    }

    // 通信が完了したら、該当タスクIDのデータを削除する
    [self.downloadParams removeObjectForKey:@(task.taskIdentifier)];
}


#pragma - NSURLSessionDownloadDelegate

- (void)URLSession:(NSURLSession *)session downloadTask:(NSURLSessionDownloadTask *)downloadTask didResumeAtOffset:(int64_t)fileOffset
    expectedTotalBytes:(int64_t)expectedTotalBytes {
    DLog(@"[didResumeAtOffset]task: %lu", (unsigned long)downloadTask.taskIdentifier);

    // do nothing
}

- (void)URLSession:(NSURLSession *)session downloadTask:(NSURLSessionDownloadTask *)downloadTask didWriteData:(int64_t)bytesWritten totalBytesWritten:(
        int64_t)totalBytesWritten totalBytesExpectedToWrite:(int64_t)totalBytesExpectedToWrite {
    DLog(@"[didWriteData]task: %lu", (unsigned long)downloadTask.taskIdentifier);

    // X-Content-Lengthを取得する
    NSDictionary *allHeaders = ((NSHTTPURLResponse *)downloadTask.response).allHeaderFields;
    int64_t xContentLength = [allHeaders[NBHeaderContentLength] longLongValue];

    // 進捗報告用のBlockをコールする
    NBURLSessionProgressBlock progressBlock = self.downloadParams[@(downloadTask.taskIdentifier)][NBKeyProgressBlock];
    if (progressBlock) {
        progressBlock(totalBytesWritten, xContentLength);
    } else {
        DLog(@"[didWriteData]progressBlock not set");
    }
}

- (void)URLSession:(NSURLSession *)session downloadTask:(NSURLSessionDownloadTask *)downloadTask didFinishDownloadingToURL:(NSURL *)location {
    DLog(@"[didFinishDownloadingToURL]task: %lu", (unsigned long)downloadTask.taskIdentifier);
    DLog(@"didFinishDownloadingToURL: location: %@", location);

    if(downloadTask.response) {
        NSInteger statusCode = ((NSHTTPURLResponse *)downloadTask.response).statusCode;
        if(statusCode != NBStatusCodeSuccess) {
            // 200 OK以外の場合、本デリゲートメソッドはコールされないはずだが、
            // 端末起動後の初回に限りコールされる現象が発生したので、そのための対策としてすぐ抜けるようにする
            DLog(@"If HTTP error occurs, didFinishDownloadingToURL should not be invoked.");
            return;
        }
    }

    // ファイルを移動してURLを通知する
    NSURL *fileURL = self.downloadParams[@(downloadTask.taskIdentifier)][NBKeyDownloadDestination];
    if (!fileURL) {
        DLog(@"[didFinishDownloadingToURL]downloadDestination not set");
        // nilのままだとmoveで例外になってしまうため置き換える
        fileURL = [NSURL URLWithString:@""];
    }

    NSFileManager *fm = [NSFileManager defaultManager];
    NSError *error = nil;

    // 同一ファイルが既に存在している場合は削除する
    // remove失敗とmove失敗は判別できるようにはしない
    [fm removeItemAtURL:fileURL error:nil];

    [fm moveItemAtURL:location toURL:fileURL error:&error];
    DLog(@"error[move]: %@", error);

    if (!error) {
        // 成功した場合は移動先のURL
        self.downloadParams[@(downloadTask.taskIdentifier)][NBKeyDownloadFileURL] = fileURL;
    } else {
        // 失敗した場合はerror
        self.downloadParams[@(downloadTask.taskIdentifier)][NBKeyDownloadMoveError] = error;
    }
}

@end
