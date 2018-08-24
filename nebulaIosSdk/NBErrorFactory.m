//
//  NBErrorFactory.m
//
//  COPYRIGHT (C) 2014 NEC CORPORATION
//


#import "NBErrorFactory.h"

@implementation NBErrorFactory

static NSString *const NBErrorDomainName = @"com.nec.ios.nebula";
static NSString *const NBCode = @"code";
static NSString *const NBDescription = @"description";
static NSString *const NBSuggestion = @"suggestion";

#pragma mark -
#pragma mark public methods

+ (NSError *)makeErrorForCode:(NBErrorCode)code {
    return [self makeErrorForCode:code withResponseBody:nil];
}

+ (NSError *)makeErrorForCode:(NBErrorCode)code withResponseBody:(NSData*)data {
    NSMutableDictionary *userInfo;
    NSNumber *actualCode = @(code);
    NSArray *errors = [self errorSet];

    // Codeの有無確認
    NSUInteger objectIndex = [[errors valueForKeyPath:NBCode] indexOfObject:actualCode];

    if (objectIndex != NSNotFound) {
        // 内部エラーのuserInfoを作成
        NSDictionary *tmpDict = errors[objectIndex];

        userInfo = [@{
                        NSLocalizedDescriptionKey : tmpDict[NBDescription],
                        NSLocalizedRecoverySuggestionErrorKey : tmpDict[NBSuggestion]
                    } mutableCopy];
    } else {
        userInfo = [@{
                        NSLocalizedDescriptionKey : @"",
                        NSLocalizedRecoverySuggestionErrorKey : @""
                    } mutableCopy];

        if (data) {
            // Dataありの場合はResponseBodyをStringに変換
            NSString *bodyString = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
            if(bodyString) {
                userInfo[NSLocalizedDescriptionKey] = bodyString;
            }
        }
    }

    return [NSError errorWithDomain:NBErrorDomainName code:code userInfo:userInfo];
}

#pragma mark -
#pragma mark private methods

/**
 *  エラーテーブルの取得
 *
 *  NSError作成用エラーテーブルを取得する。
 *  テーブルはエラーコード、エラー概要、解決策を要素としたNSDictionaryの配列。
 *
 *  @return エラーテーブル
 */
+ (NSArray *)errorSet {
    static NSArray *sErrorSet;
    if (!sErrorSet) {
        sErrorSet = @[
            @{ NBCode : @(NBErrorPreconditionError),
               NBDescription : @"Precondition Error.", NBSuggestion : @"" },
            @{ NBCode : @(NBErrorInvalidArgumentError),
               NBDescription : @"Invalid Argument Error.", NBSuggestion : @"" },
            @{ NBCode : @(NBErrorRequestError),
               NBDescription : @"Request Error.", NBSuggestion : @"" },
            @{ NBCode : @(NBErrorNoInfomation),
               NBDescription : @"No information available.", NBSuggestion : @"" },
            @{ NBCode : @(NBErrorUnsaved),
               NBDescription : @"Unsaved.", NBSuggestion : @"" },
            @{ NBCode : @(NBErrorInvalidSessionToken),
               NBDescription : @"Unable to retrieve valid session token.", NBSuggestion : @"" },
            @{ NBCode : @(NBErrorFailedToDownload),
               NBDescription : @"Failed to download.", NBSuggestion : @"" }
        ];
    }
    return sErrorSet;
}

@end
