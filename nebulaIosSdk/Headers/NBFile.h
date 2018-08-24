//
//  NBFile.h
//
//  COPYRIGHT (C) 2014 NEC CORPORATION
//


#import <Foundation/Foundation.h>
#import "NBBlocks.h"
@class NBAcl;

NS_ASSUME_NONNULL_BEGIN

/**
 *  ファイルストレージクラス
 *
 *  ファイルストレージに格納される ファイル1件を表現する。
 */
@interface NBFile : NSObject

/**
 *  ファイルバケット名
 */
@property (nonatomic, readonly, nullable) NSString *bucketName;

/**
 *  メタデータのID
 */
@property (nonatomic, readonly, nullable) NSString *objectId;

/**
 *  ファイル名
 */
@property (nonatomic, nullable) NSString *fileName;

/**
 *  Content-Type
 */
@property (nonatomic, nullable) NSString *contentType;

/**
 *  ファイルサイズ（バイト数）
 */
@property (nonatomic,readonly) long long contentLength;

/**
 *  ACL
 */
@property (nonatomic, nullable) NBAcl *acl;

/**
 *  作成日時
 */
@property (nonatomic, readonly, nullable) NSDate *created;

/**
 *  更新日時
 */
@property (nonatomic, readonly, nullable) NSDate *updated;

/**
 *  メタデータのETag
 */
@property (nonatomic, nullable) NSString *etag;

/**
 *  ファイル本体のETag
 */
@property (nonatomic) NSString *fileEtag;

/**
 *  公開URL
 */
@property (nonatomic, readonly) NSString *publicUrl;

/**
 *  Bucket名を指定したNBFileの生成を行う
 *
 *  @param bucketName Objectが所属するBucket名
 *
 *  @return NBFileのインスタンス
 */
+ (instancetype)objectWithBucketName:(NSString *)bucketName
NS_SWIFT_UNAVAILABLE("Use designated initializer");

/**
 *  Bucketを指定したイニシャライザ
 *
 *  @param bucketName Objectが所属するBucket名
 *
 *  @return NBFileのインスタンス
 */
- (instancetype)initWithBucketName:(nullable NSString *)bucketName NS_DESIGNATED_INITIALIZER;

/**
 *  ファイルを新規アップロードする（Url指定）
 *
 *  以下のパラメータをプロパティにて指定可能
 *  ・ファイル名
 *  ・ACL
 *  ・Content-Type
 *
 *  @param url           ファイルパス
 *  @param resultBlock   実行結果を受け取るブロック
 *  @param progressBlock 転送進捗を受け取るブロック
 */
- (void)uploadNewFileInBackgroundWithURL:(NSURL*)url resultBlock:(NBFilesBlock)resultBlock progressBlock:(nullable NBFileProgressBlock)
    progressBlock NS_SWIFT_NAME(uploadNewFileInBackground(url:completion:progress:));

/**
 *  ファイルを新規アップロードする（Data指定）
 *
 *  以下のパラメータをプロパティにて指定可能
 *  ・ファイル名
 *  ・ACL
 *  ・Content-Type
 *
 *  @param data          ファイルデータ
 *  @param resultBlock   実行結果を受け取るブロック
 *  @param progressBlock 転送進捗を受け取るブロック
 */
- (void)uploadNewFileInBackgroundWithData:(NSData*)data resultBlock:(NBFilesBlock)resultBlock progressBlock:(nullable NBFileProgressBlock)
    progressBlock NS_SWIFT_NAME(uploadNewFileInBackground(data:completion:progress:));

/**
 *  ファイルをダウンロードする
 *
 *  以下のパラメータをプロパティにて指定可能
 *  ・ファイル名
 *
 *  @param url           保存先
 *  @param downloadBlock 実行結果を受け取るブロック
 *  @param progressBlock 転送進捗を受け取るブロック
 */
- (void)downloadFileInBackgroundWithURL:(NSURL*)url downloadBlock:(NBFileDownloadBlock)downloadBlock progressBlock:(nullable NBFileProgressBlock)
    progressBlock NS_SWIFT_NAME(downloadInBackground(url:completion:progress:));

/**
 *  ファイルを更新アップロードする（Url指定）
 *
 *  以下のパラメータをプロパティにて指定可能
 *  ・ファイル名
 *  ・Content-Type
 *  ・メタデータのETag
 *  ・ファイル本体のETag
 *
 *  @param url           ファイルパス
 *  @param resultBlock   実行結果を受け取るブロック
 *  @param progressBlock 転送進捗を受け取るブロック
 */
- (void)uploadUpdateFileInBackgroundWithURL:(NSURL*)url resultBlock:(NBFilesBlock)resultBlock progressBlock:(nullable NBFileProgressBlock)
    progressBlock NS_SWIFT_NAME(uploadUpdateFileInBackground(url:completion:progress:));

/**
 *  ファイルを更新アップロードする（Data指定）
 *
 *  以下のパラメータをプロパティにて指定可能
 *  ・ファイル名
 *  ・Content-Type
 *  ・メタデータのETag
 *  ・ファイル本体のETag
 *
 *  @param data          ファイルデータ
 *  @param resultBlock   実行結果を受け取るブロック
 *  @param progressBlock 転送進捗を受け取るブロック
 */
- (void)uploadUpdateFileInBackgroundWithData:(NSData*)data resultBlock:(NBFilesBlock)resultBlock progressBlock:(nullable NBFileProgressBlock)
    progressBlock NS_SWIFT_NAME(uploadUpdateFileInBackground(data:completion:progress:));

/**
 *  特定ファイルのメタデータを更新する
 *
 *  以下のパラメータをプロパティにて指定可能
 *  ・メタデータのETag
 *  ・ファイル名
 *  ・Content-Type
 *  ・ACL
 *
 *  @param filename  更新対象ファイル名
 *  @param block 実行結果を受け取るブロック
 */
- (void)updateFileInBackgroundWithFilename:(NSString*)filename block:(NBFilesBlock)block
NS_SWIFT_NAME(updateInBackground(filename:comletion:));

/**
 *  特定ファイルを削除する
 *
 *  以下のパラメータをプロパティにて指定可能
 *  ・ファイル名
 *  ・メタデータのETag
 *  ・ファイル本体のETag
 *
 *  @param block 実行結果を受け取るブロック
 */
- (void)deleteFileInBackgroundWithBlock:(NBFilesBlock)block
NS_SWIFT_NAME(deleteInBackground(completion:));

/**
 *  特定ファイルを公開する
 *
 *  以下のパラメータをプロパティにて指定可能
 *  ・ファイル名
 *  ・メタデータのETag
 *
 *  @param block 実行結果を受け取るブロック
 */
- (void)enablePublishFileInBackgroundWithBlock:(NBFilesBlock)block
NS_SWIFT_NAME(enablePublishInBackground(completion:));

/**
 *  特定ファイルの公開を解除する
 *
 *  以下のパラメータをプロパティにて指定可能
 *  ・ファイル名
 *  ・メタデータのETag
 *
 *  @param block 実行結果を受け取るブロック
 */
- (void)disablePublishFileInBackgroundWithBlock:(NBFilesBlock)block
NS_SWIFT_NAME(disablePublishInBackground(completion:));

/**
 *  プロパティにdictionaryの情報を反映する
 *
 *  @param dictionary オブジェクトに設定するkey-Valueのdictionary
 */
- (void)setPropertiesWithDictionary:(NSDictionary *)dictionary
NS_SWIFT_NAME(setProperties(dictionary:));

@end

NS_ASSUME_NONNULL_END
