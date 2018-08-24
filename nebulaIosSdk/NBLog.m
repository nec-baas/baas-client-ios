//
//  NBLog.m
//
//  COPYRIGHT (C) 2014 NEC CORPORATION
//


#import "Headers/NBSettings.h"

#import "NBLog.h"
#import "Common.h"

@implementation NBLog

/**
 *  出力ログの最大長
 */
static const NSInteger NBLogLength = 512;

#pragma mark -
#pragma mark public methods

+ (void)logURLRequest:(NSURLRequest *)request {
    DLog(@"operationMode : %ld", (long)[NBSettings operationMode]);
    if ([NBSettings operationMode] == NBOperationModeDebug) {
        NSLog(@"method : %@\n"
              "URL    : %@\n"
              "headers: %@\n"
              "query  : %@\n"
              "body   : %@",
              request.HTTPMethod,
              request.URL,
              request.allHTTPHeaderFields,
              request.URL.query,
              [NBLog cutLog:[NBLog stringWithData:request.HTTPBody]]);
    }
}

+ (void)logURLResponse:(NSURLResponse *)response body:(NSData *)body error:(NSError *)error {
    DLog(@"operationMode : %ld", (long)[NBSettings operationMode]);
    if ([NBSettings operationMode] == NBOperationModeDebug) {
        NSLog(@"statusCode: %ld\n"
              "headers   : %@\n"
              "body      : %@\n"
              "error     : %@",
              (long)((NSHTTPURLResponse *)response).statusCode,
              ((NSHTTPURLResponse *)response).allHeaderFields,
              [NBLog cutLog:[NBLog stringWithData:body]],
              [error description]);
    }
}

#pragma mark -
#pragma mark private methods

/**
 *  NSDataをNSStringに変換する。
 *
 *  @param data 変換対象のNSData
 *
 *  @return 変換後の文字列
 */
+ (NSString *)stringWithData:(NSData *)data {
    return [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
}

/**
 *  ログを一定の長さに丸め込む。
 *  長さは定数NBLogLengthにて指定可能。
 *
 *  @param log 変換対象の文字列
 *
 *  @return 変換後の文字列
 */
+ (NSString *)cutLog:(NSString *)log {
    DLog("length: %lu", (unsigned long)[log length]);
    if ([log length] > NBLogLength) {
        log = [log substringToIndex:NBLogLength];
    }
    return log;
}

@end
