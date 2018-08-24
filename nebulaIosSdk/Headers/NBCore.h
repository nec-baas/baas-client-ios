//
//  NBCore.h
//
//  COPYRIGHT (C) 2014 NEC CORPORATION
//


#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/**
 *  初期化クラス
 *
 *  アプリ全体の設定値のうち、起動時に一度だけ設定するパラメータを保持する。
 */
@interface NBCore : NSObject <NSCopying>

/**
 *  アプリケーションID、アプリケーションキー、テナントIDの初期化を行う。
 *
 *  @param appId    アプリケーションID
 *  @param appKey   アプリケーションキー
 *  @param tenantId テナントID
 */
+ (void)setUpWithAppId:(nonnull NSString *)appId appKey:(nonnull NSString *)appKey tenantId:(nonnull NSString *)tenantId
NS_SWIFT_NAME(setUp(appId:appKey:tenantId:));

/**
 *  エンドポイントURIを設定する。nilを設定するとクラウド用URIとなる。
 *
 *  @param endPointUri エンドポイントURI
 */
+ (void)setEndPointUri:(nonnull NSString *)endPointUri
NS_SWIFT_NAME(set(endPointUri:));

/**
 *  アプリケーションIDを取得する。
 *
 *  @return アプリケーションID
 */
+ (NSString *)appId;

/**
 *  アプリケーションキーを取得する。
 *
 *  @return アプリケーションキー
 */
+ (NSString *)appKey;

/**
 *  テナントIDを取得する。
 *
 *  @return テナントID
 */
+ (NSString *)tenantId;

/**
 *  エンドポイントURIを取得する。
 *
 *  @return エンドポイントURI
 */
+ (NSString *)endPointUri;

/**
 *  セッションの再生成およびcompletionHandlerの保存
 *
 *  UIApplicationDelegate handleEventsForBackgroundURLSessionでコールする必要がある。
 *
 *  @param identifier        再生成するセッションのID
 *  @param completionHandler システムへ完了を通知するcompletionHandler
 */
+ (void)recreateSessionWithIdentifier:(NSString *)identifier completionHandler:(void (^)(void))completionHandler
NS_SWIFT_NAME(recreateSession(identifier:completaionHandler:));

@end

NS_ASSUME_NONNULL_END

