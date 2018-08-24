//
//  NBObjectBucketManager.h
//
//  COPYRIGHT (C) 2014 NEC CORPORATION
//


#import <Foundation/Foundation.h>
@class NBObjectBucket;

NS_ASSUME_NONNULL_BEGIN

/**
 *  ObjectBucketの管理クラス
 *
 *  Bucketの生成を行う。
 */
@interface NBObjectBucketManager : NSObject <NSCopying>

/**
 *  クラスファクトリ
 *
 *  本メソッドを使用してインスタンスを取得すること。
 *
 *  @return NBObjectBucketManagerのインスタンス
 */
+ (NBObjectBucketManager *)sharedInstance;

/**
 *  NBObjectBucketの生成
 *
 *  @param name バケット名
 *
 *  @return NBObjectBucketのインスタンス
 */
- (NBObjectBucket *)bucketWithName:(NSString *)name  NS_SWIFT_NAME(bucket(name:));

@end

NS_ASSUME_NONNULL_END
