//
//  NBURLRequestFactory.m
//
//  COPYRIGHT (C) 2014 NEC CORPORATION
//


#import "Headers/NBCore.h"
#import "Headers/NBAcl.h"

#import "NBURLRequestFactory.h"
#import "NBSessionInfo.h"
#import "NBErrorFactory.h"
#import "NBUtilities.h"
#import "Common.h"

/**
 *  インスタンス変数
 */
@interface NBURLRequestFactory ()
@property (nonatomic) NSMutableURLRequest *request;
@property (nonatomic) NSURL *url;
@property (nonatomic) NSString *appId;               // アプリケーションID
@property (nonatomic) NSString *appKey;              // アプリケーションキー
@property (nonatomic) NSString *tenantId;            // テナントID
@property (nonatomic) NSString *endPointUri;         // エンドポイントURI
@end

@implementation NBURLRequestFactory

/**
 *  定数
 */
static NSString *const NBHeaderAppId = @"X-Application-Id";
static NSString *const NBHeaderAppKey = @"X-Application-Key";
static NSString *const NBHeaderSessionToken = @"X-Session-Token";
static NSString *const NBHeaderAcl = @"X-ACL";

static NSString *const NBHeaderContentType = @"Content-Type";
static NSString *const NBHeaderContentTypeJson = @"application/json";
static NSString *const NBPathApiVersion = @"1";      // バージョン番号

#pragma mark -
#pragma mark public methods

+ (NSURLRequest *)makeRequestForMethod:(NBHTTPMethod)method
    url:(NSString *)apiUrl
    useToken:(NBUseSessionToken)useSessionToken
    error:(NSError **)error {
    return [[[self alloc] initWithApiUrl:apiUrl]
            makeRequestForMethod:method useToken:useSessionToken header:nil param:nil body:nil error:error];
}

+ (NSURLRequest *)makeRequestForMethod:(NBHTTPMethod)method
    url:(NSString *)apiUrl
    useToken:(NBUseSessionToken)useSessionToken
    param:(NSDictionary *)param
    error:(NSError **)error {
    return [[[self alloc] initWithApiUrl:apiUrl]
            makeRequestForMethod:method useToken:useSessionToken header:nil param:param body:nil error:error];
}

+ (NSURLRequest *)makeRequestForMethod:(NBHTTPMethod)method
    url:(NSString *)apiUrl
    useToken:(NBUseSessionToken)useSessionToken
    body:(NSData *)body
    error:(NSError **)error {
    return [[[self alloc] initWithApiUrl:apiUrl]
            makeRequestForMethod:method useToken:useSessionToken header:nil param:nil body:body error:error];
}

+ (NSURLRequest *)makeRequestForMethod:(NBHTTPMethod)method
    url:(NSString *)apiUrl
    useToken:(NBUseSessionToken)useSessionToken
    param:(NSDictionary *)param
    body:(NSData *)body
    error:(NSError **)error {
    return [[[self alloc] initWithApiUrl:apiUrl]
            makeRequestForMethod:method useToken:useSessionToken header:nil param:param body:body error:error];
}

+ (NSURLRequest *)makeRequestForMethod:(NBHTTPMethod)method
    url:(NSString *)apiUrl
    useToken:(NBUseSessionToken)useSessionToken
    header:(NSDictionary *)header
    param:(NSDictionary *)param
    error:(NSError **)error {
    return [[[self alloc] initWithApiUrl:apiUrl]
            makeRequestForMethod:method useToken:useSessionToken header:header param:param body:nil error:error];
}


#pragma mark -
#pragma mark private methods

/**
 *  イニシャライザ
 *
 *  インスタンス変数の初期化を行う。
 *
 *  @return クラスインスタンス
 */
- (instancetype)initWithApiUrl:(NSString *)apiUrl {
    // 本クラスはライブラリ内でのみ使用されるため、init()のオーバーライドは省略する

    self = [super init];
    if (self == nil) {
        return nil;
    }

    // エンドポイントURI、テナントID、アプリケーションID、アプリケーションキー取得
    NSString *endPointUriTemp = [NBCore endPointUri];
    if ([endPointUriTemp hasSuffix:@"/"] == NO) {
        self.endPointUri = [endPointUriTemp stringByAppendingString:@"/"];
    }
    else {
        self.endPointUri = [NSString stringWithString:endPointUriTemp];
    }
    DLog(@"endPointUri is KindOfClass :%@", [self.endPointUri isKindOfClass:[NSURL class]] ? @"YES" : @"NO");
    self.tenantId = [NBCore tenantId];
    self.appId = [NBCore appId];
    self.appKey = [NBCore appKey];

    // URL設定
    self.url = [NSURL URLWithString:
                [NSString stringWithFormat:@"%@%@/%@%@",
                 self.endPointUri, NBPathApiVersion, self.tenantId, apiUrl]];
    
    if (!self.url){
        [[NSException exceptionWithName:NSInvalidArgumentException
                                 reason:@"Invalid URL."
                               userInfo:nil] raise];
    }
    
    // URLリクエスト生成
    self.request = [NSMutableURLRequest requestWithURL:self.url];

    return self;
}

/**
 *  リクエスト生成
 *
 *  リクエストを生成する。
 *
 *  @param method          メソッド
 *  @param useSessionToken セッショントークン指定
 *  @param header          リクエストヘッダ
 *  @param param           リクエストパラメータ
 *  @param body            リクエストボディ
 *  @param error           エラー内容
 *
 *  @return 生成したリクエスト
 */
- (NSMutableURLRequest *)makeRequestForMethod:(NBHTTPMethod)method
    useToken:(NBUseSessionToken)useSessionToken
    header:(NSDictionary *)header
    param:(NSDictionary *)param
    body:(NSData *)body
    error:(NSError **)error {
    // リクエストパラメータ設定
    if (param) {
        [self setParam:param];
    }
    // リクエストボディ設定
    if (body) {
        [self setJsonToBody:body];
    }
    // 共通HTTPヘッダ設定
    [self setCommonHeaderWithMethod:method useToken:useSessionToken error:error];
    // 拡張HTTPヘッダ設定
    // 既にエラーが発生していたらスキップする
    if (!*error && header) {
        [self setExtendedHeader:header error:error];
    }

    return self.request;
}

/**
 *  リクエストパラメータ設定
 *
 *  リクエストパラメータ（クエリパラメータ）を設定する。
 *
 *  @param param リクエストパラメータ
 */
- (void)setParam:(NSDictionary *)param {
    // クエリ文字列取得
    NSString *queryString = [self queryStringWithDictionary:param];

    if ([queryString length]) {
        // 空文字でない場合は、クエリパラメータ設定
        self.url =
            [NSURL URLWithString:[[self.url absoluteString] stringByAppendingFormat:[[self.url absoluteString] rangeOfString:@"?"].location ==
                                  NSNotFound ? @"?%@":@"&%@", queryString]];
        [self.request setURL:self.url];
    }
}

/**
 *  クエリ文字列生成
 *
 *  NSDictionary型のクエリパラメータからクエリ文字列に変換する。
 *
 *  @param param リクエストパラメータ
 *
 *  @return クエリ文字列
 */
- (NSString *)queryStringWithDictionary:(NSDictionary *)param {
    NSString *queryString = @"";
    BOOL firstParam = YES;

    for (id key in param) {
        id value = param[key];
        if (value) {
            // key=valueの形にする
            NSString *part = [NSString stringWithFormat:@"%@=%@",
                              [NBUtilities encodeURI:key], [NBUtilities encodeURI:value]];
            if (firstParam) {
                queryString = [NSString stringWithFormat:@"%@%@", queryString, part];
            }
            else {
                // &でつなぐ
                queryString = [NSString stringWithFormat:@"%@&%@", queryString, part];
            }
            firstParam = NO;
        }
    }

    return queryString;
}

/**
 *  リクエストボディ設定
 *
 *  リクエストボディ（JSON）を設定する。
 *
 *  @param body リクエストボディ（JSON）
 */
- (void)setJsonToBody:(NSData *)body {
    // Content-Type:"application/json"設定
    [self.request setValue:NBHeaderContentTypeJson forHTTPHeaderField:NBHeaderContentType];
    // リクエストボディ設定
    [self.request setHTTPBody:body];
}

/**
 *  共通ヘッダ設定
 *
 *  HTTPメソッドと共通ヘッダを設定する。
 *
 *  @param method          メソッド
 *  @param useSessionToken セッショントークン指定
 *  @param error           エラー内容
 */
- (void)setCommonHeaderWithMethod:(NBHTTPMethod)method useToken:(NBUseSessionToken)useSessionToken error:(NSError **)error {
    // メソッド設定
    [self.request setHTTPMethod:[self stringWithNBHTTPMethod:method]];

    // X-Application-Id:設定
    [self.request setValue:self.appId forHTTPHeaderField:NBHeaderAppId];
    // X-Application-Key:設定
    [self.request setValue:self.appKey forHTTPHeaderField:NBHeaderAppKey];

    // X-Session-Token:設定
    NSString *sessionToken = [NBSessionInfo sessionToken];
    switch (useSessionToken) {
        case NBUseSessionTokenNotUse :
            // Do Nothing
            break;

        case NBUseSessionTokenMust:
        case NBUseSessionTokenOptional:
            if (sessionToken) {
                [self.request setValue:sessionToken forHTTPHeaderField:NBHeaderSessionToken];
            }
            else {
                // セッショントークンがない場合
                if (useSessionToken == NBUseSessionTokenMust) {
                    // X-Session-Token:が必須の場合は、エラー
                    *error = [NBErrorFactory makeErrorForCode:NBErrorInvalidSessionToken];
                    self.request = nil;
                }                 // else { Do Nothing }
            }
            break;

        default:
            // パラメータ異常
            DLog(@"Switch default. useSessionToken is %ld.", (long)useSessionToken);
            *error = [NBErrorFactory makeErrorForCode:NBErrorInvalidArgumentError];
            self.request = nil;
            break;
    }
}

- (void)setExtendedHeader:(NSDictionary *)header error:(NSError **)error {
    for (NSString *aKey in header) {
        if ([aKey isEqualToString:NBHeaderAcl]) {
            // X-ACL:設定
            NSDictionary *aclDictionary = header[aKey];
            NSData *jsonData = [NSJSONSerialization dataWithJSONObject:aclDictionary options:0 error:error];
            if (*error) {
                self.request = nil;
                return;
            }
            NSString *aclString = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
            [self.request setValue:aclString forHTTPHeaderField:aKey];
        }
        else {
            // その他の設定
            // ex) Content-Type:
            [self.request setValue:header[aKey] forHTTPHeaderField:aKey];
        }
    }
}

/**
 *  HTTPメソッド名取得
 *
 *  NBHTTPMethod型からHTTPメソッド文字列に変換する。
 *
 *  @param method メソッド
 *
 *  @return HTTPメソッド文字列
 */
- (NSString *)stringWithNBHTTPMethod:(NBHTTPMethod)method {
    switch (method) {
        case NBHTTPMethodGET:
            return @"GET";

        case NBHTTPMethodPOST:
            return @"POST";

        case NBHTTPMethodPUT:
            return @"PUT";

        case NBHTTPMethodDELETE:
            return @"DELETE";

        default:
            DLog(@"Switch default. method is %ld.", (long)method);
            return @"GET";
    }
}

@end
