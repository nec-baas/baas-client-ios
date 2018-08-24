//
//  NBRestExecutor.h
//
//  COPYRIGHT (C) 2014 NEC CORPORATION
//


#import <Foundation/Foundation.h>

/**
 *   ブロック定義
 *   通信結果を返すブロック
 *
 *  @param data  レスポンスボディ
 *  @param error エラー内容
 */
typedef void (^NBResponseBlock) (NSData *data, NSError *error);

/**
 *   ブロック定義
 *   通信の進捗結果を返すブロック
 *
 *  @param transferred 転送完了したデータサイズ
 *  @param expected    総データサイズ
 */
typedef void (^NBResponseProgressBlock) (int64_t transferred, int64_t expected);

/**
 *   ブロック定義
 *   通信結果を返すブロック(ダウンロード)
 *
 *  @param url   レスポンスボディ(ダウンロードしたファイルのURL)
 *  @param error エラー内容
 */
typedef void (^NBResponseDownloadBlock) (NSURL *url, NSError *error);


/** RestExecutorクラス
 *  NBURLSessionクラスと上位クラスとの仲介とスレッド管理を行う
 */
@interface NBRestExecutor : NSObject

/**
 *  インスタンスの名称
 */
@property (nonatomic, readonly) NSString *requestName;

/**
 *  RestExecutor生成
 *  インスタンスを生成して返却する
 *
 *  @param request 通信を行う情報を設定したRequest
 *  @param name    コール元識別子 インスタンスを生成するAPI名を推奨 設定後はrequestNameから参照
 *
 *  @return RestExecutorのインスタンス
 */
+ (NBRestExecutor*)executorWithRequest:(NSURLRequest*)request name:(NSString*)name;

/**
 *  非同期通信実行要求
 *  NBURLSessionへ非同期実行を要求する
 *  応答はmain threadで実行する。
 *
 *  @param block 通信結果を返すブロック
 */
- (void)executeRequestInBackgroundWithBlock:(NBResponseBlock)block;

/**
 *  非同期通信実行要求(ダウンロード)
 *  NBURLSessionへ非同期実行を要求する
 *  応答はmain threadで実行する。
 *
 *  @param fileURL       ダウンロードするファイルの保存先URL
 *  @param block         実行結果を受け取るブロック
 *  @param progressBlock 転送進捗を受け取るブロック
 */
- (void)executeDownloadRequestInBackgroundWithURL:(NSURL *)fileURL block:(NBResponseDownloadBlock)block progressBlock:(NBResponseProgressBlock)
    progressBlock;

/**
 *  非同期通信実行要求(アップロード)
 *  NBURLSessionへ非同期実行を要求する
 *  応答はmain threadで実行する。
 *
 *  @param fileURL       アップロードするファイルのURL
 *  @param block         実行結果を受け取るブロック
 *  @param progressBlock 転送進捗を受け取るブロック
 */
- (void)executeUploadRequestInBackgroundWithURL:(NSURL *)fileURL block:(NBResponseBlock)block progressBlock:(NBResponseProgressBlock)
    progressBlock;

@end
