//
//  NBSessionInfo.h
//
//  COPYRIGHT (C) 2014 NEC CORPORATION
//


#import <Foundation/Foundation.h>

/**
 *  セッション情報クラス
 *
 *  セッショントークンやユーザ情報を取得・保存するクラス
 */

@interface NBSessionInfo : NSObject

/**
 *  セッショントークンの有効期限取得
 *
 *  セッショントークンの有効期限を取得する。
 *  取得できなかった場合は@0を返却する。
 *
 *  @return セッショントークンの有効期限
 */
+ (NSNumber *)expiration;

/**
 *  セッショントークン取得
 *
 *  セッショントークンを取得する。
 *  取得できなかった場合はnilを返却する。
 *
 *  @return セッショントークン
 */
+ (NSString *)sessionToken;

/**
 *  ユーザ情報取得
 *
 *  ユーザ情報を取得する。
 *  取得できなかった場合はnilを返却する。
 *
 *  @return ユーザ情報
 */
+ (NSDictionary *)sessionUser;

/**
 *  ユーザ情報保存
 *
 *  ユーザ情報を保存する。
 *
 *  @param user 保存するユーザ情報
 */
+ (void)setSessionUser:(NSDictionary *)user;

/**
 *  セッショントークン保存
 *
 *  セッショントークンを保存する。
 *
 *  @param sessionToken 保存するセッショントークン
 *  @param expiration   保存するセッショントークンの有効期限
 */
+ (void)setSessionToken:(NSString *)sessionToken expiration:(NSNumber *)expiration;

/**
 *  セッション情報破棄
 *
 *  セッション情報（セッショントークンやユーザ情報）を破棄する。
 */
+ (void)clearSessionInfo;

@end
