//
//  NBErrorFactory.h
//
//  COPYRIGHT (C) 2014 NEC CORPORATION
//


#import <Foundation/Foundation.h>
#import "Headers/NBErrorCode.h"

/**
 *  NebulaSDK固有エラー生成クラス
 *
 *  エラーコードからNSErrorを作成する。
 */

@interface NBErrorFactory : NSObject {}

/**
 *  Nebulaライブラリ固有エラー生成
 *
 *  NBErrorCodeまたはHTTPStatusCodeに従いNSErrorを生成する。
 *
 *  @param code エラーコード
 *
 *  @return エラー情報
 */
+ (NSError*)makeErrorForCode:(NBErrorCode)code;

/**
 *  Nebulaライブラリ固有エラー生成
 *
 *  NBErrorCodeまたはHTTPStatusCodeに従いNSErrorを生成する。
 *  レスポンスボディが指定された場合、その内容をNSErrorに設定する。
 *
 *  @param code エラーコード
 *  @param data レスポンスボディー
 *
 *  @return エラー情報
 */
+ (NSError *)makeErrorForCode:(NBErrorCode)code withResponseBody:(NSData*)data;

@end
