//
//  NBLog.h
//
//  COPYRIGHT (C) 2014 NEC CORPORATION
//


#import <Foundation/Foundation.h>

/**
 *  ログ出力クラス
 */
@interface NBLog : NSObject

/**
 *  URLRequestの内容をログ出力する。
 *
 *  @param request 出力対象のURLRequest
 */
+ (void)logURLRequest:(NSURLRequest *)request;

/**
 *  URLResponseの内容をログ出力する。
 *
 *  @param response 出力対象のURLResponse
 *  @param body     出力対象のレスポンスボディ
 *  @param error    出力対象のエラー情報
 */
+ (void)logURLResponse:(NSURLResponse *)response body:(NSData *)body error:(NSError *)error;

@end
