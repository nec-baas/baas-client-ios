//
//  NBObject.h
//
//  COPYRIGHT (C) 2014 NEC CORPORATION
//


#import <Foundation/Foundation.h>
#import "NBBlocks.h"
@class NBAcl;

NS_ASSUME_NONNULL_BEGIN

/**
 *  Objectクラス
 *
 *  オブジェクトストレージに格納される JSON オブジェクトデータ1件を表現する。
 */
@interface NBObject : NSObject

/**
 *  ObjectのACL
 */
@property (nonatomic, nullable) NBAcl *acl;

/**
 *  Objectの所属するBucket名
 */
@property (nonatomic, readonly, nullable) NSString *bucket;

/**
 *  ObjectのID
 */
@property (nonatomic, readonly, nullable) NSString *objectId;

/**
 *  Objectの作成日時
 */
@property (nonatomic, readonly, nullable) NSDate *created;

/**
 *  Objectの更新日時
 */
@property (nonatomic, readonly, nullable) NSDate *updated;

/**
 *  ObjectのETag
 */
@property (nonatomic, readonly, nullable) NSString *etag;

/**
 *  Bucket名を指定したNBObjectの生成を行う
 *
 *  @param bucketName Objectが所属するBucket名
 *
 *  @return NBObjectのインスタンス
 */
+ (instancetype)objectWithBucketName:(NSString *)bucketName
NS_SWIFT_UNAVAILABLE("Use designated initializer");

/**
 *  Bucketを指定したイニシャライザ
 *
 *  @param bucketName Objectが所属するBucket名
 *
 *  @return NBObjectのインスタンス
 */
- (instancetype)initWithBucketName:(nullable NSString *)bucketName NS_DESIGNATED_INITIALIZER;

/**
 *  指定のkeyに対応する値を取得する
 *
 *  @param key オブジェクトのキー
 *
 *  @return keyに対応するオブジェクト
 *  対応するものがない場合はnilを返却する。
 */
- (nullable id)objectForKey:(NSString *)key  NS_SWIFT_NAME(object(forKey:));

/**
 *  指定のkey-valueを格納する。
 *
 *  @param object objectはJSONに変換可能なもののみ許容する。
 *                NSString, NSNumber, NSArray, NSDictionary等。
 *                重複するキーを指定した場合には上書きを行う。
 *                nil を指定した場合はキーが削除される。
 *  @param key    オブジェクトのキー
 */
- (void)setObject:(id)object forKey:(NSString *)key;

/**
 *  オブジェクトに格納されたkeyを取得する
 *
 *  @return キーの配列。NSStringの要素を格納する。
 */
- (NSArray<NSString *> *)allKeys;

/**
 *  指定されたキーに対応する値を削除する。
 *
 *  @param key 削除対象オブジェクトのキー
 */
- (void)removeObjectForKey:(NSString *)key NS_SWIFT_NAME(remove(forKey:));

/**
 *  オブジェクトの削除を行う。
 *
 *  サーバーにオブジェクトが格納されていない場合はエラーとなる。
 *
 *  @param block 削除の結果を通知するBlock
 */
- (void)deleteInBackgroundWithBlock:(NBResultBlock)block
NS_SWIFT_NAME(deleteInBackground(completion:));

/**
 *  オブジェクトの保存を行う。
 *
 *  オブジェクトがサーバーに保存されていない場合は新規作成、
 *  オブジェクトがサーバーに保存されている場合は上書き更新を行う。
 *  上書き更新時にはACLの指定は省略できない。
 *
 *  @param block 保存の結果を通知するBlock。
 *               結果のNBObjectの配列には保存した1件のみが格納される。
 */
- (void)saveInBackgroundWithBlock:(NBObjectsBlock)block
NS_SWIFT_NAME(saveInBackground(completion:));

/**
 *  オブジェクトの部分更新を行う。
 *
 *  ObjectIdが設定されていないオブジェクトの更新は失敗する。
 *
 *  @param dictionary 部分更新するデータのdictionary
 *  @param block      更新結果を通知するBlock
 */
- (void)partUpdateInBackgroundWithDictionary:(NSDictionary *)dictionary block:(NBObjectsBlock)block
NS_SWIFT_NAME(partUpdateInBackground(dictionary:completion:));

/**
 *  オブジェクトに設定されている情報をdictionary形式で返却する
 *
 *  @return オブジェクトが保持しているkey-Valueのdictionary
 */
- (NSDictionary<NSString *, id> *)dictionaryValue;

/**
 *  オブジェクトにdictionaryの情報を反映する
 *
 *  @param dictionary オブジェクトに設定するkey-Valueのdictionary
 *         JSONオブジェクトに設定可能なオブジェクトのみを含むこと
 */
- (void)setObjectDataWithDictionary:(NSDictionary<NSString *, id> *)dictionary
NS_SWIFT_NAME(setObjectData(dictionary:));

/**
 *  指定のkeyに対応する値を取得する
 *  objectForKey:と同様である。
 *
 *  @param key オブジェクトのキー
 *
 *  @return keyに対応するオブジェクト
 *  対応するものがない場合はnilを返却する。
 */
- (nullable id)objectForKeyedSubscript:(NSString*)key;

/**
 *  指定のkey-valueを格納する。
 *  setObject:forKey:と同様である。
 *
 *  @param object objectはJSONに変換可能なもののみ許容する。
 *                NSString, NSNumber, NSArray, NSDictionary等。
 *                nil, NSNullは許容しない。
 *                重複するキーを指定した場合には上書きを行う。
 *  @param key    オブジェクトのキー
 */
- (void)setObject:(id)object forKeyedSubscript:(NSString*)key;

@end

NS_ASSUME_NONNULL_END
