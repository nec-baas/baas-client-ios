//
//  NBFileManager.h
//
//  COPYRIGHT (C) 2014 NEC CORPORATION
//


#import <Foundation/Foundation.h>

/**
 *  FileManagerクラス
 *
 *  フォルダ作成、プロパティリスト読み出し・保存を行うクラス
 */

@interface NBFileManager : NSObject

/**
 *  インスタンス取得
 *
 *  インスタンスを返す。
 *
 *  @return インスタンス
 */
+ (instancetype)sharedManager;

/**
 *  プロパティリスト保存
 *
 *  プロパティリストにデータを保存する。
 *
 *  @param plist プロパティリスト名
 *  @param data  保存データ
 *  @param error エラー内容
 *
 *  @return 処理結果（YES:成功/NO:失敗）
 */
- (BOOL)saveToPlist:(NSString *)plist data:(NSDictionary *)data error:(NSError **)error;

/**
 *  プロパティリスト読み出し
 *
 *  プロパティリストの内容を読み出す。
 *  読み出しに失敗した場合はnilを返却する。
 *
 *  @param plist プロパティリスト名
 *  @param error エラー内容
 *
 *  @return プロパティリスト内容
 */
- (NSDictionary *)loadFromPlist:(NSString *)plist error:(NSError **)error;

/**
 *  特定キーの値取得
 *
 *  プロパティリスト内の特定キーの値を取得する。
 *  読み出しに失敗した場合はnilを返却する。
 *
 *  @param plist プロパティリスト名
 *  @param key   キー
 *  @param error エラー内容
 *
 *  @return 値
 */
- (id)objectFromPlist:(NSString *)plist key:(id)key error:(NSError **)error;

/**
 *  プロパティリスト削除
 *
 *  プロパティリストを削除する。
 *
 *  @param plist プロパティリスト名
 *  @param error エラー内容
 *
 *  @return 処理結果（YES:成功/NO:失敗）
 */
- (BOOL)deletePlist:(NSString *)plist error:(NSError **)error;

@end
