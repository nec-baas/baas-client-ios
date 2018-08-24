//
//  NBBlocks.h
//
//  COPYRIGHT (C) 2014 NEC CORPORATION
//


#ifndef nebulaIosSdk_NBBlocks_h
#define nebulaIosSdk_NBBlocks_h

@class NBUser;
@class NBPushInstallation;
@class NBGroup;
@class NBObject;
@class NBFile;

/**
 *  ユーザ情報の取得結果を受け取るBlock
 *
 *  @param user  ユーザ情報
 *  @param error エラー内容
 */
typedef void (^NBUserBlock)(NBUser *user, NSError *error);

/**
 *  ユーザ情報の取得結果(リスト)を受け取るBlock
 *
 *  @param users ユーザ情報リスト
 *  @param error エラー内容
 */
typedef void (^NBUsersBlock)(NSArray<NBUser *> *users, NSError *error);


/**
 *  グループ情報の取得結果(リスト)を受け取るBlock
 *
 *  @param groups グループ情報リスト
 *  @param error  エラー内容
 */
typedef void (^NBGroupsBlock)(NSArray<NBGroup *> *groups, NSError *error);


/**
 *  Object取得時のBlock
 *
 *  @param objects NBObjectの配列。
 *  @param count   検索にマッチした件数。
 *                 オジェクトのクエリ、かつNBQueryのqueryCountをYESに設定した場合のみ格納される。
 *                 それ以外のケースでは不定値となる。
 *  @param error   処理中にエラーが発生した場合に設定される。
 *                 nil以外の場合にはobjects,countは参照しないこと。
 */
typedef void (^NBObjectsBlock)(NSArray<NBObject *> *objects, NSUInteger count, NSError *error);

/**
 *  インスタレーション情報を受け取るBlock
 *
 *  @param installation インスタレーション情報
 *  @param error        エラー内容
 */
typedef void (^NBPushInstallationBlock)(NBPushInstallation *installation, NSError *error);

/**
 *  Push送信結果を受け取るBlock
 *
 *  @param result Push送信結果
 *                成功時は該当したインスタレーション数を含む。
 *  @param error  エラー内容
 */
typedef void (^NBPushBlock)(NSDictionary<NSString *, NSObject *> *result, NSError *error);

/**
 *  非同期処理のコールバックBlock
 *
 *  @param error 処理結果 処理に成功した場合nilとなる。
 */
typedef void (^NBResultBlock)(NSError *error);

/**
 *  ファイルメタデータを受け取るBlock
 *
 *  @param datalist ファイルメタデータリスト
 *  @param error    エラー内容
 */
typedef void (^NBFilesBlock)(NSArray<NBFile *> *datalist, NSError *error);

/**
 *  転送進捗を受け取るBlock
 *
 *  @param transferred 総転送サイズ（byte）
 *  @param expected    ファイル全体サイズ（byte）
 */
typedef void (^NBFileProgressBlock)(int64_t transferred, int64_t expected);

/**
 *  ダウンロード完了通知を受け取るBlock
 *
 *  @param url   ファイル保存先
 *  @param error エラー内容
 */
typedef void (^NBFileDownloadBlock)(NSURL *url, NSError *error);

#endif
