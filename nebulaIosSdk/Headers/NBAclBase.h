//
//  NBAclBase.h
//
//  COPYRIGHT (C) 2014 NEC CORPORATION
//



#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/**
 *  権限一覧
 */
typedef NS_ENUM (NSInteger,NBAclPermission) {
    /**
     *  読み込み
     */
    NBAclReadable NS_SWIFT_NAME(readable) = 0,
    /**
     *  書き込み
     */
    NBAclWritable NS_SWIFT_NAME(writable),
    /**
     *  作成
     */
    NBAclCreatable NS_SWIFT_NAME(creatable),
    /**
     *  削除
     */
    NBAclDeletable NS_SWIFT_NAME(deletable),
    /**
     *  更新
     */
    NBAclUpdatable NS_SWIFT_NAME(updatable),
    /**
     *  管理者
     */
    NBAclAdmin NS_SWIFT_NAME(admin),
    /**
     *  オーナ
     */
    NBAclOwner NS_SWIFT_NAME(owner)
};

/**
 *  ACL基底クラス
 *
 *  ２種類のACLクラスの共通部
 */
@interface NBAclBase : NSObject

/**
 *  読み込み許可リスト
 */
@property (nonatomic) NSMutableArray<NSString *> *r;

/**
 *  書き込み許可リスト
 */
@property (nonatomic) NSMutableArray<NSString *> *w;

/**
 *  更新許可リスト
 */
@property (nonatomic) NSMutableArray<NSString *> *u;

/**
 *  作成許可リスト
 */
@property (nonatomic) NSMutableArray<NSString *> *c;

/**
 *  削除許可リスト
 */
@property (nonatomic) NSMutableArray<NSString *> *d;

/**
 *  権限追加
 *
 *  権限許可リストにユーザIDまたはグループを追加する。
 *
 *  @param entry      ユーザIDまたはグループ名
 *  @param permission 権限
 *
 *  @return 処理結果（YES:成功/NO:失敗）
 */
- (BOOL)addEntry:(NSString *)entry permission:(NBAclPermission)permission;

/**
 *  権限削除
 *
 *  権限許可リストからユーザIDまたはグループを削除する。
 *
 *  @param entry      ユーザIDまたはグループ名
 *  @param permission 権限
 *
 *  @return 処理結果（YES:成功/NO:失敗）
 */
- (BOOL)removeEntry:(NSString *)entry permission:(NBAclPermission)permission;

/**
 *  権限許可リスト一括取得
 *
 *  設定済みの権限情報をNSDictionary型で返却する。
 *
 *  @return 権限リスト
 */
- (NSDictionary *)entriesDictionary;

/**
 *  権限許可リスト一括設定
 *
 *  権限をNSDictionary型で一括設定する。
 *
 *  @param dictionary 権限リスト
 */
- (void)setEntriesDictionary:(NSDictionary *)dictionary;

@end

NS_ASSUME_NONNULL_END
