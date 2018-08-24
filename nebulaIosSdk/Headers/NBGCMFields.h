//
//  NBGCMFields.h
//
//  COPYRIGHT (C) 2014 NEC CORPORATION
//


#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/**
 *  GCMメッセージフィールドクラス
 *
 *  Pushメッセージ内のAndroid固有値データクラス
 */
@interface NBGCMFields : NSObject

/**
 *  システムバーに表示するタイトル
 *
 *  初期値はnil、nilオブジェクトは要求時のデータには含まれない。
 */
@property (nonatomic, nullable) NSString *title;

/**
 *  通知を開いたときに起動する URI
 *
 *  初期値はnil、nilオブジェクトは要求時のデータには含まれない。
 */
@property (nonatomic, nullable) NSString *uri;

/**
 *  GCMメッセージフィールドインスタンス作成
 *
 *  GCMメッセージフィールドインスタンスを作成する。
 *
 *  @return GCMメッセージフィールドインスタンス
 */
+ (NBGCMFields *)createFields NS_SWIFT_NAME(init());

/**
 *  GCMメッセージフィールドデータ取得
 *
 *  GCMメッセージフィールドクラスのオブジェクトをNSDictionary型で取得する。
 *  nilオブジェクト、NSNull値を持つKeyは含まれない。
 *
 *  @return NSDictionaryデータ
 */
- (NSDictionary<NSString *, id> *)dictionaryValue;

@end

NS_ASSUME_NONNULL_END
