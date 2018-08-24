//
//  NBObjectBucket.h
//
//  COPYRIGHT (C) 2014 NEC CORPORATION
//


#import <Foundation/Foundation.h>
#import "NBBlocks.h"
@class NBQuery;
@class NBObject;

NS_ASSUME_NONNULL_BEGIN

/**
 *  ObjectBucketクラス
 *
 *  所属するNBObjectの管理機能を提供する。
 */
@interface NBObjectBucket : NSObject

/**
 *  Bucket名
 *
 *  bucket生成時に指定したbucket名
 */
@property (nonatomic, readonly, copy) NSString *bucketName;

- (instancetype)init NS_SWIFT_UNAVAILABLE("Use designated initializer");

/**
 *  bucket名を指定したイニシャライザ (指定イニシャライザ)
 *
 *  @param bucketName Bucket名
 *
 *  @return 初期化したインスタンス
 */
- (instancetype)initWithBucketName:(NSString *)bucketName NS_DESIGNATED_INITIALIZER;

/**
 *  Objectの取得処理
 *
 *  オブジェクトIDを指定してバケットからNebulaObjectを検索する。
 *
 *  @param id       取得対象のObjectId
 *  @param block    処理結果のコールバック。NBObjectsListBlockのシグネチャのBlockを指定すること。
 */
- (void)getObjectInBackgroundWithId:(NSString *)id block:(NBObjectsBlock)block
NS_SWIFT_NAME(getObjectInBackground(objectId:completion:));

/**
 *  BucketからObjectを検索する。
 *
 *  @param query  検索条件を設定したNBQuery
 *  @param block  処理結果のコールバック。NBObjectsListBlockのシグネチャのBlockを指定すること。
 */
- (void)queryInBackgroundWithQuery:(NBQuery *)query block:(NBObjectsBlock)block
NS_SWIFT_NAME(queryInBackground(query:completion:));

/**
 *  NBObjectの生成
 *
 *  NBObjectを新規作成する場合に使用する。
 *
 *  @return Bucket名で初期化したNBObjectのインスタンス
 */
- (NBObject *)createObject;

@end

NS_ASSUME_NONNULL_END
