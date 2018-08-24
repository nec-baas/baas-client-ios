//
//  NBURLSession.h
//
//  COPYRIGHT (C) 2014 NEC CORPORATION
//


#import <Foundation/Foundation.h>

/**
 *  URLSessionクラス
 *
 *  NSURLSessionクラスを使って、HTTP/HTTPS通信を行うクラス
 */
@interface NBURLSession : NSObject

/**
 *  ブロック定義
 *
 *  通信結果を返すブロック
 *
 *  @param data     レスポンスボディ
 *  @param response レスポンスヘッダ
 *  @param error    エラー内容
 */
    typedef void (^NBURLSessionBlock) (NSData *data, NSURLResponse *response, NSError *error);

/**
 *  ブロック定義
 *
 *  通信結果を返すブロック
 *
 *  @param trasferred 転送完了したデータサイズ
 *  @param expected   総データサイズ
 */
typedef void (^NBURLSessionProgressBlock) (int64_t trasferred, int64_t expected);

/**
 *  ブロック定義
 *
 *  通信結果を返すブロック(ダウンロード)
 *
 *  @param url      レスポンスボディ(ダウンロードしたファイルのURL)
 *  @param serverErrorBody     レスポンスボディ(サーバーの応答がエラーの場合のみ有効)
 *  @param response レスポンスヘッダ
 *  @param error    エラー内容
 */
typedef void (^NBURLSessionDownloadBlock) (NSURL *url, NSData *serverErrorBody,NSURLResponse *response, NSError *error);


/**
 *  インスタンス取得
 *
 *  インスタンスを返す。
 *
 *  @return インスタンス
 */
+ (instancetype)sharedInstance;

/**
 *  通信実行（Dataタスク）
 *
 *  NSURLSession Dataタスクを生成して通信を行う。
 *
 *  @param request リクエスト内容
 *  @param block   通信結果を返すブロック
 */
- (void)dataTaskWithRequest:(NSURLRequest *)request block:(NBURLSessionBlock)block;

/**
 *  通信実行（Downloadタスク）
 *
 *  NSURLSession Downloadタスクを生成して通信を行う。
 *
 *  @param request       リクエスト内容
 *  @param fileURL       ダウンロードするファイルの保存先URL
 *  @param downloadBlock 実行結果を受け取るブロック
 *  @param progressBlock 転送進捗を受け取るブロック
 */
- (void)downloadTaskWithRequest:(NSURLRequest *)request toURL:(NSURL *)fileURL block:(NBURLSessionDownloadBlock)downloadBlock progressBlock:(
        NBURLSessionProgressBlock)progressBlock;

/**
 *  通信実行（Uploadタスク）
 *
 *  NSURLSession Uploadタスクを生成して通信を行う。
 *
 *  @param request       リクエスト内容
 *  @param fileURL       アップロードするファイルのURL
 *  @param block         実行結果を受け取るブロック
 *  @param progressBlock 転送進捗を受け取るブロック
 */
- (void)uploadTaskWithRequest:(NSURLRequest *)request fromFile:(NSURL *)fileURL block:(NBURLSessionBlock)block progressBlock:(
        NBURLSessionProgressBlock)progressBlock;

/**
 *  セッション生成
 *
 *  セッションの再生成およびcompletionHandlerの保存
 *
 *  UIApplicationDelegate handleEventsForBackgroundURLSessionでコールする必要がある。
 *
 *  @param identifier        再生成するセッションのID
 *  @param completionHandler システムへ完了を通知するcompletionHandler
 */
- (void)recreateSessionWithIdentifier:(NSString *)identifier completionHandler:(void (^)(void))completionHandler;

/**
 *  セッション生成
 *
 *  DataTask用のセッションを生成する
 */
- (void)createDataSession;

/**
 *  セッション生成
 *
 *  DownloadTask用のセッションを生成する
 */
- (void)createDownloadSession;

/**
 *  セッション生成
 *
 *  UploadTask用のセッションを生成する
 */
- (void)createUploadSession;

/**
 *  一時ファイル操作
 *
 *  NSDataから一時ファイルを生成する
 *
 *  @param data  アップロードするデータ
 *  @param error エラー内容
 *  @return 生成した一時ファイルのファイルURL
 */
+ (NSURL *)createTemporaryFileWithData:(NSData *)data error:(NSError **)error;

/**
 *  一時ファイル操作
 *
 *  一時ファイルを削除する
 *
 *  @param fileURL 削除するファイルのURL
 *  @param error   エラー内容
 */
+ (void)removeTemporaryFileWithURL:(NSURL *)fileURL error:(NSError **)error;

@end
