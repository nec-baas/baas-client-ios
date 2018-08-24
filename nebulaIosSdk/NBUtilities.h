//
//  NBUtilities.h
//
//  COPYRIGHT (C) 2014 NEC CORPORATION
//


#import <Foundation/Foundation.h>

@interface NBUtilities : NSObject

    extern NSString *const NBObjectApiUrl;
extern NSString *const NBFileApiUrl;

extern NSString *const NBKeyBlock;
extern NSString *const NBKeyProgressBlock;
extern NSString *const NBKeyDownloadDestination;
extern NSString *const NBKeyCompletionHandler;

/**
 *  URIエンコード
 *
 *  URIエンコーディングをする。
 *
 *  @param UriString エンコード前の文字列
 *
 *  @return エンコード後の文字列
 */
+ (NSString *)encodeURI:(NSString *)UriString;

/**
 *  フィールド名の文字列チェック
 *
 *  @param string チェック対象のString
 *  半角英数と"_",$(MongoDBの演算子のため)が許容される。
 *
 *  @return Yes:正常 NO:異常
 */
+ (BOOL)checkFieldNameWithString:(NSString *)string;

/**
 *  日時をJSONの文字列からNSDateに変換する
 *
 *  @param dateString String形式の日時
 *
 *  @return 変換したNSDate
 */
+ (NSDate *)dateWithString:(NSString *)dateString;

/**
 *  日時をNSDateからJSONの文字列に変換する
 *
 *  @param date NSDate型の日時
 *
 *  @return 変換したJSON String型の
 */
+ (NSString *)stringWithDate:(NSDate *)date;

/**
 *  整数値チェック
 *
 *  文字列が数字のみで構成されているかどうかをチェックする。
 *
 *  @param string 文字列
 *
 *  @return チェック結果（YES:整数値/NO:整数値ではない）
 */
+ (BOOL)isDigit:(NSString *)string;

@end
