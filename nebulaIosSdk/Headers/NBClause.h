//
//  NBClause.h
//
//  COPYRIGHT (C) 2014 NEC CORPORATION
//


#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/**
 *  Clauseクラス
 *
 *  Queryの検索条件として使用する。
 */
@interface NBClause : NSObject <NSCopying>

/**
  *  正規表現検索時のオプション
  */
typedef NS_OPTIONS (NSUInteger, NBRegexCaseOptions) {
    /**
      *  Option指定無し
      */
    NBRegexCaseNone NS_SWIFT_NAME(none) = 0,
    /**
     *  大文字と小文字を区別しない。
     */
    NBRegexCaseInsensitivity NS_SWIFT_NAME(insensitivity) = 1 << 0,
    /**
      *  文字列を複数行として扱う。
      */
    NBRegexCaseMultiLine NS_SWIFT_NAME(multiline) = 1 << 1,
    /**
      *  拡張正規表現を使用する。
      */
    NBRegexCaseExtended NS_SWIFT_NAME(extended) = 1 << 2,
    /**
      *  正規表現の.が改行にもマッチする。
      */
    NBRegexCaseDotMultiLine NS_SWIFT_NAME(dotMultiline) = 1 << 3,
};


/**
 *  keyで指定されたフィールドの値が、valueで指定された値と等しいこと。
 *
 *  @param key   演算対象のフィールド
 *  @param value 値
 *
 *  @return 条件を設定したNBClauseのインスタンス
 */
+ (NBClause*)equals:(NSString*)key value:(id)value;

/**
 *  keyで指定されたフィールドの値が、valueで指定された値と等しくないこと。
 *
 *  @param key   演算対象のフィールド
 *  @param value 値
 *
 *  @return 条件を設定したNBClauseのインスタンス
 */
+ (NBClause*)notEquals:(NSString*)key value:(id)value;

/**
 *  keyで指定されたフィールドの値が、valueで指定された値より小さいこと。
 *
 *  @param key   演算対象のフィールド
 *  @param value 値
 *
 *  @return 条件を設定したNBClauseのインスタンス
 */
+ (NBClause*)lessThan:(NSString*)key value:(id)value;

/**
 *  keyで指定されたフィールドの値が、valueで指定された値以下であること。
 *
 *  @param key   演算対象のフィールド
 *  @param value 値
 *
 *  @return 条件を設定したNBClauseのインスタンス
 */
+ (NBClause*)lessThanOrEqual:(NSString*)key value:(id)value;

/**
 *  keyで指定されたフィールドの値が、valueで指定された値より大きいこと。
 *
 *  @param key   演算対象のフィールド
 *  @param value 値
 *
 *  @return 条件を設定したNBClauseのインスタンス
 */
+ (NBClause*)greaterThan:(NSString*)key value:(id)value;

/**
 *  keyで指定されたフィールドの値が、valueで指定された値以上であること。
 *
 *  @param key   演算対象のフィールド
 *  @param value 値
 *
 *  @return 条件を設定したNBClauseのインスタンス
 */
+ (NBClause*)greaterThanOrEqual:(NSString*)key value:(id)value;

/**
 *  keyで指定されたフィールドの値が、valuesで指定された値のいずれかに一致すること。
 *
 *  @param key   演算対象のフィールド
 *  @param values 値
 *
 *  @return 条件を設定したNBClauseのインスタンス
 */
+ (NBClause*)in:(NSString*)key value:(NSArray*)values;

/**
 *  keyで指定されたフィールドの値が、valuesで指定された値の全てに一致すること。
 *
 *  @param key   演算対象のフィールド
 *  @param values 値
 *
 *  @return 条件を設定したNBClauseのインスタンス
 */
+ (NBClause*)all:(NSString*)key value:(NSArray*)values;

/**
 *  keyで指定されたフィールドの値の有無。
 *
 *  @param key   演算対象のフィールド
 *  @param value 値は以下のように扱う YES: 存在する NO:存在しない
 *
 *  @return 条件を設定したNBClauseのインスタンス
 */
+ (NBClause*)exists:(NSString*)key value:(BOOL)value;

/**
 *  keyで指定されたフィールドの値が、正規表現で与えられた表記と一致すること。
 *
 *  @param key    演算対象のフィールド
 *  @param value  正規表現
 *  @param options オプション　設定値はNBRegexCaseOptionを参照。複数条件は|で和をとって設定可能である。
 *
 *  @return 条件を設定したNBClauseのインスタンス
 */
+ (NBClause*)regex:(NSString*)key expression:(NSString*)value options:(NBRegexCaseOptions)options;

/**
 *  引数で与えられた検索条件のandをとる。
 *
 *  @param clauses 条件を設定したClauseの配列
 *
 *  @return 条件を設定したNBClauseのインスタンス
 */
+ (NBClause*)and:(NSArray<NBClause*> *)clauses;

/**
 *  引数で与えられた検索条件のorをとる。
 *
 *  @param clauses 条件を設定したClauseの配列
 *
 *  @return 条件を設定したNBClauseのインスタンス
 */
+ (NBClause*)or:(NSArray<NBClause*> *)clauses;

/**
 *  引数で与えられた検索条件のnotをとる。
 *
 *  @param clause 条件を設定したClause
 *
 *  @return 条件を設定したNBClauseのインスタンス
 */
+ (NBClause*)not:(NBClause*)clause;

/**
 *  設定された条件をNSDictionary形式で返却する
 *
 *  @return 現在の設定条件のdictionary
 */
- (NSDictionary<NSString*, id> *)dictionaryValue;

@end

NS_ASSUME_NONNULL_END

