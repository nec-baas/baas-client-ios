//
//  NBQuery.h
//
//  COPYRIGHT (C) 2014 NEC CORPORATION
//


#import <Foundation/Foundation.h>
@class NBClause;

NS_ASSUME_NONNULL_BEGIN

/**
 *  Queryクラス
 *
 *  検索条件を集約するクラス。NBObjectの検索に使用する。
 */
@interface NBQuery : NSObject

/**
 *  検索上限数
 *
 *  設定可能な範囲は0〜100。未設定の場合は条件を設定しない。
 *  0未満の場合は未設定と見なす。
 */
@property (nonatomic) NSInteger limit;

/**
 *  スキップカウント
 *
 *  スキップカウントの有効範囲は0以上の値とする。
 *  0未満の場合は未設定と見なす。
 */
@property (nonatomic) NSInteger skip;

/**
 *  検索条件に合致した件数
 *
 *  YES: 件数取得を行う (初期値)
 *  NO:  件数取得を行わない
 */
@property (nonatomic) BOOL queryCount NS_SWIFT_NAME(isQueryCount);

/**
 *  検索条件とするNBClause
 */
@property (nonatomic, nullable) NBClause *clause;

/**
 *  NBClauseの条件を設定したNBQueryを生成する。
 *
 *  @param clause Queryに設定する検索条件
 *
 *  @return NBQueryのインスタンス
 */
+ (NBQuery*)queryWithClause:(NBClause*)clause  NS_SWIFT_NAME(init(clause:));

/**
 *  ソート条件設定
 *
 *  複数のキーを設定した場合、設定順にソートを行う
 *
 *  @param key       ソート条件とするフィールド
 *  @param sortOrder YES: 昇順 NO: 降順
 */
- (void)setSortOrderWithKey:(NSString*)key isAscend:(BOOL)sortOrder  NS_SWIFT_NAME(setSortOrder(key:isAscend:));

/**
 *  ソート条件取得
 *
 *  設定されているソート条件を取得する
 *
 *  @return ソート条件　配列にはNSDictionary型の要素を格納する
 *  複数のソート条件を設定した場合は設定順に配列に格納されてる。
 *  フィールド名をキーに昇順、降順のパラメータが取得可能。
 */
- (NSArray<NSString *> *)sortOrder;

@end

NS_ASSUME_NONNULL_END

