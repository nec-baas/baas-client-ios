//
//  NBPushInstallation.h
//
//  COPYRIGHT (C) 2014 NEC CORPORATION
//


#import <Foundation/Foundation.h>
#import "NBBlocks.h"

NS_ASSUME_NONNULL_BEGIN

/**
 *  Pushインスタレーションクラス
 *
 *  インスタレーション登録/更新/削除/取得を行うクラス
 */
@interface NBPushInstallation : NSObject

/**
 *  OS種別
 */
@property (nonatomic, readonly, nullable) NSString *osType;

/**
 *  OSバージョン
 */
@property (nonatomic, readonly, nullable) NSString *osVersion;

/**
 *  Device Token
 *
 *  初期値はnil、nilオブジェクトは要求時のデータには含まれない。
 */
@property (nonatomic, nullable) NSString *deviceToken;

/**
 *  使用する Push テクノロジを指定する
 */
@property (nonatomic, readonly, nullable) NSString *pushType;

/**
 *  購読するチャネルの一覧
 *
 *  初期値はnil、nilオブジェクトは要求時のデータには含まれない。
 */
@property (nonatomic, nullable) NSArray *channels;

/**
 *  アプリケーションのバージョンコード
 */
@property (nonatomic, readonly, nullable) NSNumber *appVersionCode;

/**
 *  アプリケーションのバージョン
 */
@property (nonatomic, readonly, nullable) NSString *appVersionString;

/**
 *  このインスタレーションに対して Push を送信可能なユーザ・グループを指定する。
 *
 *  初期値は@[@"g:anonymous"]、nilオブジェクトは要求時のデータには含まれない。
 */
@property (nonatomic) NSArray *allowedSenders;

/**
 *  任意のKey-Value
 *
 *  初期値はnil、nilオブジェクトは要求時のデータには含まれない。
 */
@property (nonatomic, nullable) NSDictionary<NSString *, id> *options;

/**
 *  インスタレーションID
 */
@property (nonatomic, readonly, nullable) NSString *installationId;

/**
 *  オーナー情報
 */
@property (nonatomic, readonly, nullable) NSString *owner;

/**
 *  インスタレーション登録
 *
 *  インスタレーションの新規登録/完全上書き更新を行う。
 *
 *  @param block 登録/更新結果を受け取るブロック
 */
- (void)saveInBackgroundWithBlock:(NBPushInstallationBlock)block
NS_SWIFT_NAME(saveInBackground(completion:));

/**
 *  インスタレーション部分更新
 *
 *  インスタレーションの部分更新を行う。
 *
 *  @param dictionary 部分更新するデータのdictionary
 *  @param block      更新結果を受け取るブロック
 */
+ (void)partUpdateInBackgroundWithDictionary:(NSDictionary*)dictionary block:(NBPushInstallationBlock)block
NS_SWIFT_NAME(partUpdateInBackground(dictionary:completion:));

/**
 *  Device Token設定
 *
 *  deviceTokenを16進数表記に変換し、@property deviceTokenに設定する。
 *
 *  @param deviceTokenData deviceToken(NSData型)
 */
- (void)setDeviceTokenFromData:(NSData *)deviceTokenData
NS_SWIFT_NAME(setDeviceToken(fromData:));

/**
 *  インスタレーション情報取得
 *
 *  インスタレーション情報をキャッシュから取得する(通信を行わない)。
 *
 *  @return 取得したインスタレーション情報
 */
+ (NBPushInstallation *)currentInstallation;

/**
 *  インスタレーション情報取得
 *
 *  インスタレーション情報をサーバから取得する。
 *
 *  @param block 取得結果を受け取るブロック
 */
+ (void)refreshCurrentInstallationInBackgroundWithBlock:(NBPushInstallationBlock)block
NS_SWIFT_NAME(refreshCurrentInstallationInBackground(completion:));

/**
 *  インスタレーション削除
 *
 *  インスタレーションの削除を行う。
 *
 *  @param block 実行結果を受け取るブロック
 */
- (void)deleteInBackgroundWithBlock:(NBResultBlock)block
NS_SWIFT_NAME(deleteInBackground(completion:));

@end

NS_ASSUME_NONNULL_END
