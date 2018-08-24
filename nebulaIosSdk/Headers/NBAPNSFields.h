//
//  NBAPNSFields.h
//
//  COPYRIGHT (C) 2014 NEC CORPORATION
//


#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/**
 *  APNSメッセージフィールドクラス
 *
 *  Pushメッセージ内のiOS固有値データクラス
 */
@interface NBAPNSFields : NSObject

/**
 *  バッジカウント
 *
 *  初期値はnil、nilオブジェクトは要求時のデータには含まれない。
 */
@property (nonatomic, nullable) NSNumber *badge;

/**
 *  Application Bundle 内のサウンドファイル名
 *
 *  初期値はnil、nilオブジェクトは要求時のデータには含まれない。
 */
@property (nonatomic, nullable) NSString *sound;

/**
 *  1にセットすると、バックグランド Push を有効にする
 *
 *  初期値はnil、nilオブジェクトは要求時のデータには含まれない。
 */
@property (nonatomic, nullable) NSNumber *contentAvailable;

/**
 *  Notification カテゴリ
 *
 *  初期値はnil、nilオブジェクトは要求時のデータには含まれない。
 */
@property (nonatomic, nullable) NSString *category;

/**
 *  APNSメッセージフィールドインスタンス作成
 *
 *  APNSメッセージフィールドインスタンスを作成する。
 *
 *  @return APNSメッセージフィールドインスタンス
 */
+ (NBAPNSFields *)createFields NS_SWIFT_NAME(init());

/**
 *  APNSメッセージフィールドデータ取得
 *
 *  APNSメッセージフィールドクラスのオブジェクトをNSDictionary型で取得する。
 *  nilオブジェクト、NSNull値を持つKeyは含まれない。
 *
 *  @return NSDictionaryデータ
 */
- (NSDictionary<NSString *, id> *)dictionaryValue;

@end

NS_ASSUME_NONNULL_END

