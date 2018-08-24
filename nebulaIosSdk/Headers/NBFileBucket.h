//
//  NBFileBucket.h
//
//  COPYRIGHT (C) 2014 NEC CORPORATION
//


#import <Foundation/Foundation.h>
#import "NBFile.h"
#import "NBBlocks.h"

NS_ASSUME_NONNULL_BEGIN

/**
 *  ファイルバケットクラス
 *
 *  所属するファイルの管理機能を提供する。
 */

@interface NBFileBucket : NSObject


/**
 *  検索対象指定
 */
typedef NS_ENUM (NSInteger,NBFileCondition) {
    /**
     *  指定なし
     */
    NBFileConditionNone = 0,
    /**
     *  公開ファイルのみ
     */
    NBFileConditionPublished
};

/**
 *  バケット名
 */
@property (nonatomic, readonly, copy) NSString *bucketName;

- (instancetype)init NS_SWIFT_UNAVAILABLE("Use designated initializer");

/**
 *  バケット名を指定したイニシャライザ
 *
 *  @param name バケット名
 *
 *  @return 初期化したインスタンス
 */
- (instancetype)initWithName:(NSString *)name NS_DESIGNATED_INITIALIZER;

/**
 *  Objectの生成
 *
 *  Objectを新規作成する場合に使用する。
 *
 *  @return バケット名で初期化したNBFileのインスタンス
 */
- (NBFile *)createObject;

/**
 *  ファイル一覧(メタデータ)をダウンロードする
 *
 *  リクエストパラメータで指定がある場合は、公開済みファイル一覧をダウンロードする
 *
 *  @param condition  ファイル公開状態
 *  @param block      実行結果を受け取るブロック
 */
- (void)queryFileInBackgroundWithCondition:(NBFileCondition)condition block:(NBFilesBlock)block
NS_SWIFT_NAME(queryFileInBackground(condition:completion:));

/**
 *  特定ファイルのメタデータを取得する
 *
 *  @param filename       取得希望ファイル名
 *  @param block      実行結果を受け取るブロック
 */
- (void)getFileInBackgroundWithFilename:(NSString *)filename block:(NBFilesBlock)block
NS_SWIFT_NAME(getFileInBackground(filename:completion:));

@end

NS_ASSUME_NONNULL_END
