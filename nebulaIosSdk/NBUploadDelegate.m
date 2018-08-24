//
//  NBUploadDelegate.m
//
//  COPYRIGHT (C) 2014 NEC CORPORATION
//


#import "NBUploadDelegate.h"
#import "NBUtilities.h"
#import "Common.h"

@implementation NBUploadDelegate

/**
 *  uploadParams用のキー
 *  レスポンスボディ
 */
static NSString *const NBKeyResponseData = @"responseData";


- (instancetype)init {
    self = [super init];

    if (self) {
        self.uploadParams = [NSMutableDictionary dictionary];
    }

    return self;
}


#pragma mark - NSURLSessionDelegate

- (void)URLSessionDidFinishEventsForBackgroundURLSession:(NSURLSession *)session {
    DLog(@"URLSessionDidFinishEventsForBackgroundURLSession: %@", session.configuration.identifier);
    // NSURLSessionDownloadTaskのdelegate実行後に呼ばれる
    // ここでOSに完了を通知

    DLog(@"Background URL session %@ finished events.", session);

    void (^completionHandler)(void) = self.uploadParams[NBKeyCompletionHandler];
    if (completionHandler) {
        [self.uploadParams removeObjectForKey:NBKeyCompletionHandler];
        completionHandler();
    } else {
        DLog(@"completionHandler not set");
    }
}


#pragma - NSURLSessionTaskDelegate

// Tells the delegate that the task finished transferring data.
- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task didCompleteWithError:(NSError *)error {
    DLog(@"[didCompleteWithError]task: %lu", (unsigned long)task.taskIdentifier);
    DLog(@"[didCompleteWithError]task: %@", task.taskDescription);
    DLog(@"didCompleteWithError: error: %@", error);

    DLog(@"uploadParams  : %@", self.uploadParams);

    // レスポンスボディを取り出す
    NSMutableData *responseData = self.uploadParams[@(task.taskIdentifier)][NBKeyResponseData];

    // 一時ファイルを削除する
    NSError *removeError = nil;
    [NBURLSession removeTemporaryFileWithURL:[NSURL URLWithString:task.taskDescription] error:&removeError];
    if (removeError) {
        DLog(@"removeError: %@", removeError);
    }

    // 完了報告用のBlockをコールする
    NBURLSessionBlock uploadBlock = self.uploadParams[@(task.taskIdentifier)][NBKeyBlock];
    if (uploadBlock) {
        uploadBlock(responseData, task.response, error);
    } else {
        DLog(@"uploadBlock not set");
    }

    // 通信が完了したら、該当タスクIDのデータを削除する
    [self.uploadParams removeObjectForKey:@(task.taskIdentifier)];
}

// Periodically informs the delegate of the progress of sending body content to the server.
- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task didSendBodyData:(int64_t)bytesSent totalBytesSent:(int64_t)totalBytesSent
    totalBytesExpectedToSend:(int64_t)totalBytesExpectedToSend {
    DLog(@"[didSendBodyData]task: %lu", (unsigned long)task.taskIdentifier);
    DLog(@"[didSendBodyData]task: %@", task.taskDescription);

    // 進捗報告用のBlockをコールする
    NBURLSessionProgressBlock progressBlock = self.uploadParams[@(task.taskIdentifier)][NBKeyProgressBlock];
    if (progressBlock) {
        progressBlock(totalBytesSent, totalBytesExpectedToSend);
    } else {
        DLog(@"[didSendBodyData]progressBlock not set");
    }
}


#pragma - NSURLSessionDataDelegate

// Tells the delegate that the data task finished receiving all of the expected data.
- (void)URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)dataTask didReceiveData:(NSData *)data {
    DLog(@"[didReceiveData]task: %lu: %@", (unsigned long)dataTask.taskIdentifier, data);
    DLog(@"[didReceiveData]task: %@", dataTask.taskDescription);

    // レスポンスボディを取得する
    NSMutableData *responseData = self.uploadParams[@(dataTask.taskIdentifier)][NBKeyResponseData];
    if (!responseData) {
        responseData = [NSMutableData dataWithData:data];
        self.uploadParams[@(dataTask.taskIdentifier)][NBKeyResponseData] = responseData;
    } else {
        [responseData appendData:data];
    }
}

@end
