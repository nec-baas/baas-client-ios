//
//  NBURLRequestFactory.h
//
//  COPYRIGHT (C) 2014 NEC CORPORATION
//


#import <Foundation/Foundation.h>

/**
 *  URLRequestFactoryクラス
 *
 *  リクエストパラメータ、リクエストボディ等の設定を行い、URLリクエストの生成を行うクラス
 */

@interface NBURLRequestFactory : NSObject

/**
 *  メソッド一覧
 */
    typedef NS_ENUM (NSInteger, NBHTTPMethod) {
    /**
     *  GET
     */
    NBHTTPMethodGET = 0,
    /**
     *  POST
     */
    NBHTTPMethodPOST,
    /**
     *  PUT
     */
    NBHTTPMethodPUT,
    /**
     *  DELETE
     */
    NBHTTPMethodDELETE
};

/**
 *  HTTPヘッダ：X-Session-Token指定一覧
 */
typedef NS_ENUM (NSInteger, NBUseSessionToken) {
    /**
     *  未使用
     */
    NBUseSessionTokenNotUse = 0,
    /**
     *  必須
     */
    NBUseSessionTokenMust,
    /**
     *  オプション
     */
    NBUseSessionTokenOptional
};

/**
 *  リクエスト生成
 *
 *  リクエストを生成する（HTTPヘッダ無し、リクエストパラメータ無し、リクエストボディ無し）。
 *  エラーが発生した場合はnilを返却する。
 *
 *  @param method          メソッド
 *  @param apiUrl          URI（/サービス種別 以降）
 *  @param useSessionToken セッショントークン指定
 *  @param error           エラー内容
 *
 *  @return 生成したリクエスト
 */
+ (NSURLRequest *)makeRequestForMethod:(NBHTTPMethod)method
    url:(NSString *)apiUrl
    useToken:(NBUseSessionToken)useSessionToken
    error:(NSError **)error;

/**
 *  リクエスト生成
 *
 *  リクエストを生成する（HTTPヘッダ無し、リクエストパラメータ有り、リクエストボディ無し）。
 *  エラーが発生した場合はnilを返却する。
 *
 *  @param method          メソッド
 *  @param apiUrl          URI（/サービス種別 以降）
 *  @param useSessionToken セッショントークン指定
 *  @param param           リクエストパラメータ
 *  @param error           エラー内容
 *
 *  @return 生成したリクエスト
 */
+ (NSURLRequest *)makeRequestForMethod:(NBHTTPMethod)method
    url:(NSString *)apiUrl
    useToken:(NBUseSessionToken)useSessionToken
    param:(NSDictionary *)param
    error:(NSError **)error;

/**
 *  リクエスト生成
 *
 *  リクエストを生成する（HTTPヘッダ無し、リクエストパラメータ無し、リクエストボディ有り）。
 *  エラーが発生した場合はnilを返却する。
 *
 *  @param method          メソッド
 *  @param apiUrl          URI（/サービス種別 以降）
 *  @param useSessionToken セッショントークン指定
 *  @param body            リクエストボディ
 *  @param error           エラー内容
 *
 *  @return 生成したリクエスト
 */
+ (NSURLRequest *)makeRequestForMethod:(NBHTTPMethod)method
    url:(NSString *)apiUrl
    useToken:(NBUseSessionToken)useSessionToken
    body:(NSData *)body
    error:(NSError **)error;

/**
 *  リクエスト生成
 *
 *  リクエストを生成する（HTTPヘッダ無し、リクエストパラメータ有り、リクエストボディ有り）。
 *  エラーが発生した場合はnilを返却する。
 *
 *  @param method          メソッド
 *  @param apiUrl          URI（/サービス種別 以降）
 *  @param useSessionToken セッショントークン指定
 *  @param param           リクエストパラメータ
 *  @param body            リクエストボディ
 *  @param error           エラー内容
 *
 *  @return 生成したリクエスト
 */
+ (NSURLRequest *)makeRequestForMethod:(NBHTTPMethod)method
    url:(NSString *)apiUrl
    useToken:(NBUseSessionToken)useSessionToken
    param:(NSDictionary *)param
    body:(NSData *)body
    error:(NSError **)error;

/**
 *  リクエスト生成
 *
 *  リクエストを生成する（HTTPヘッダ有り、リクエストパラメータ有り、リクエストボディ無し）。
 *  エラーが発生した場合はnilを返却する。
 *
 *  @param method          メソッド
 *  @param apiUrl          URI（/サービス種別 以降）
 *  @param useSessionToken セッショントークン指定
 *  @param header          HTTPヘッダ
 *  @param param           リクエストパラメータ
 *  @param error           エラー内容
 *
 *  @return 生成したリクエスト
 */
+ (NSURLRequest *)makeRequestForMethod:(NBHTTPMethod)method
    url:(NSString *)apiUrl
    useToken:(NBUseSessionToken)useSessionToken
    header:(NSDictionary *)header
    param:(NSDictionary *)param
    error:(NSError **)error;

@end
