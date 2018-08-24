//
//  NBUtilities.m
//
//  COPYRIGHT (C) 2014 NEC CORPORATION
//


#import "NBUtilities.h"
#import "Common.h"

@implementation NBUtilities

// global constant variables
NSString *const NBObjectApiUrl = @"/objects";
NSString *const NBFileApiUrl = @"/files";

NSString *const NBKeyBlock = @"block";
NSString *const NBKeyProgressBlock = @"progressBlock";
NSString *const NBKeyDownloadDestination = @"downloadDestination";
NSString *const NBKeyCompletionHandler = @"completionHandler";

// internal constant variables
static NSString *const NBDateFormat = @"yyyy-MM-dd'T'HH:mm:ss.SSS'Z'";
static NSString *const NBUtc = @"UTC";
static NSString *const NBFieldNameIllegalCode = @"[^A-Za-z0-9_$]+";
static NSString *const NBCachedDateFormatterKey = @"com.nec.ios.nebula.NBCachedDateFormatterKey";
static NSString *const NBCachedDigitCharacterSetKey = @"com.nec.ios.nebula.NBCachedDigitCharacterSetKey";

#pragma mark -
#pragma mark public methods

+ (NSString *)encodeURI:(NSString *)UriString {
    return (__bridge_transfer NSString *)
    CFURLCreateStringByAddingPercentEscapes(kCFAllocatorDefault, (__bridge CFStringRef)UriString, NULL,
                                            CFSTR(":/?#[]@!$&'()*+,;="), kCFStringEncodingUTF8);
}

+ (BOOL)checkFieldNameWithString:(NSString *)string {
    // 英数字、"_"、"$"以外が含まれているかの判定
    BOOL result = [self patternCheckWithString:string pattern:NBFieldNameIllegalCode];

    return result;
}

+ (NSDate *)dateWithString:(NSString *)dateString {
    NSDateFormatter *formatter = [self dateFormatter];
    NSDate *date = [formatter dateFromString:dateString];

    return date;
}

+ (NSString *)stringWithDate:(NSDate *)date {
    NSString *result = nil;

    NSDateFormatter *formatter = [self dateFormatter];
    result = [NSString stringWithFormat:@"%@", [formatter stringFromDate:date]];

    return result;
}

+ (BOOL)isDigit:(NSString *)string {
    if ([string isEqual:[NSNull null]] || ![string length]) {
        // NSNull、nil、空文字の場合
        return NO;
    }

    NSCharacterSet *characterSet = [self characterSetForIsDigit];
    NSScanner *aScanner = [NSScanner localizedScannerWithString:string];
    [aScanner setCharactersToBeSkipped:nil];
    [aScanner scanCharactersFromSet:characterSet intoString:NULL];

    if (![aScanner isAtEnd]) {
        // 数字以外が含まれている場合
        return NO;
    }

    return YES;
}

#pragma mark -
#pragma mark private methods

/**
 *  指定した正規表現のパターンに対して文字列が適合するか判定する。
 *  特定のパターンに対するチェック処理をラッパーとして別途提供する。
 *
 *  @param string  チェック対象の文字列(空文字列の場合は適合しないと判定)
 *  @param pattern 判定する正規表現
 *
 *  @return 適合可否の判定 YES:適合する NO:適合しない
 */
+ (BOOL)patternCheckWithString:(NSString *)string pattern:(NSString *)pattern {
    BOOL result = NO;
    NSRegularExpression *regex = nil;
    NSError *error = nil;
    NSArray *match = nil;

    if (pattern && string && (string.length > 0)) {
        regex = [NSRegularExpression regularExpressionWithPattern:pattern options:0 error:&error];
        if (!error) {
            match = [regex matchesInString:string options:0 range:NSMakeRange(0, string.length)];

            if (match.count == 0) {
                // 不正な文字が使用されていなかった
                result = YES;
            }
        }
        else {
            DLog(@"invalid regular expression : %@ %@ %@", string, pattern, error);
        }
    }
    else {
        DLog(@"invalid parameters : %@ %@", string, pattern);
    }

    return result;
}

/**
 *  スレッド共通のNSDataFormatterインスタンスを取得する
 *
 *  @return NSDateFormatterのインスタンス
 */
+ (NSDateFormatter *)dateFormatter {
    NSMutableDictionary *threadDictionary = [[NSThread currentThread] threadDictionary];
    NSDateFormatter *dateFormatter = threadDictionary[NBCachedDateFormatterKey];
    if (!dateFormatter) {
        dateFormatter = [[NSDateFormatter alloc] init];
        [dateFormatter setLocale:[[NSLocale alloc] initWithLocaleIdentifier:NBUtc]];
        [dateFormatter setDateFormat:NBDateFormat];

        threadDictionary[NBCachedDateFormatterKey] = dateFormatter;
    }
    return dateFormatter;
}

/**
 *  スレッド共通のNSCharacterSet(isDigit用)インスタンスを取得する
 *
 *  @return NSCharacterSetのインスタンス
 */
+ (NSCharacterSet *)characterSetForIsDigit {
    NSMutableDictionary *threadDictionary = [[NSThread currentThread] threadDictionary];
    NSCharacterSet *characterSet = threadDictionary[NBCachedDigitCharacterSetKey];
    if (!characterSet) {
        characterSet = [NSCharacterSet characterSetWithCharactersInString:@"0123456789"];

        threadDictionary[NBCachedDigitCharacterSetKey] = characterSet;
    }
    return characterSet;
}

@end
