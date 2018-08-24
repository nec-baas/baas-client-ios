//
//  NBFileBucketManager.h
//
//  COPYRIGHT (C) 2014 NEC CORPORATION
//


#import <Foundation/Foundation.h>
#import "NBFileBucket.h"
#import "NBBlocks.h"

NS_ASSUME_NONNULL_BEGIN

/**
 *  ファイルバケットの管理クラス
 *
 *  バケットの生成を行う。
 */

@interface NBFileBucketManager : NSObject

/**
 *  クラスファクトリ
 *
 *  本メソッドを使用してインスタンスを取得すること。
 *
 *  @return NBFileBucketManagerのインスタンス
 */
+ (instancetype)sharedInstance;

/**
 *  NBObjectBucketの生成
 *
 *  @param bucketName バケット名
 *
 *  @return NBFileBucketのインスタンス
 */
- (NBFileBucket *)bucketWithBucketName:(NSString *)bucketName
NS_SWIFT_NAME(bucket(bucketName:));

@end

NS_ASSUME_NONNULL_END
