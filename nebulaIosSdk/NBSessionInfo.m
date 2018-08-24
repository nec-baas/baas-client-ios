//
//  NBSessionInfo.m
//
//  COPYRIGHT (C) 2014 NEC CORPORATION
//


#import "NBSessionInfo.h"
#import "NBFileManager.h"
#import "Common.h"

/**
 *  インスタンス変数
 */
@interface NBSessionInfo ()
@property (nonatomic) NBFileManager *fileManager;       // NBFileManagerインスタンス
@end

@implementation NBSessionInfo

/**
 *  定数
 */
static NSString * const NBUserPlist = @"user.plist";   // プロパティリストファイル名
// Key
static NSString * const NBKeySessionToken = @"sessionToken";
static NSString * const NBKeySessionTokenExpiration = @"expiration";

#pragma mark -
#pragma mark public methods

+ (NSNumber *)expiration {
    NBSessionInfo *sessionInfo = [[self alloc] init];
    NSError *error = nil;

    // ファイル読み込み、特定キー取得
    NSNumber *expiration = [sessionInfo.fileManager objectFromPlist:NBUserPlist key:NBKeySessionTokenExpiration error:&error];

    if (error || !expiration || [expiration isEqual:[NSNull null]]) {
        // 取得できなかった場合とNSNullの場合は@0を返す
        if (error) {
            DLog(@"error: %@", error.description);
        }
        return @0;
    }

    return expiration;
}

+ (NSString *)sessionToken {
    NBSessionInfo *sessionInfo = [[self alloc] init];
    NSError *error = nil;

    // ファイル読み込み、特定キー取得
    NSString *value = [sessionInfo.fileManager objectFromPlist:NBUserPlist key:NBKeySessionToken error:&error];

    if (error) {
        // 取得できなかった場合、nilを返す
        DLog(@"error: %@", error.description);
    }

    return value;
}

+ (NSDictionary *)sessionUser {
    NBSessionInfo *sessionInfo = [[self alloc] init];
    NSError *error = nil;

    // ファイル読み込み
    NSDictionary *dict = [sessionInfo.fileManager loadFromPlist:NBUserPlist error:&error];

    if (error) {
        // 取得できなかった場合、nilを返す
        DLog(@"error: %@", error.description);
        return nil;
    }

    // NBUserのProperty分のみ返す
    NSMutableDictionary *mdict = [dict mutableCopy];
    [mdict removeObjectForKey:NBKeySessionToken];
    [mdict removeObjectForKey:NBKeySessionTokenExpiration];

    return mdict;
}

+ (void)setSessionUser:(NSDictionary *)user {
    NBSessionInfo *sessionInfo = [[self alloc] init];
    NSError *error = nil;
    NSArray *array = [self userKeys];

    // ファイル読み込み
    NSDictionary *dict = [sessionInfo.fileManager loadFromPlist:NBUserPlist error:&error];

    NSMutableDictionary *mdict;
    if (dict) {
        mdict = [dict mutableCopy];

        // 前回分を削除する
        for (id key in array) {
            [mdict removeObjectForKey:key];
        }
    } else {
        mdict = [NSMutableDictionary dictionary];
    }

    // ユーザ情報部分を更新
    for (id key in array) {
        if (user[key]) {
            mdict[key] = user[key];
        }
    }

    // ファイル保存
    error = nil;
    BOOL result = [sessionInfo.fileManager saveToPlist:NBUserPlist data:mdict error:&error];

    if (!result || error) {
        DLog(@"result: %@", (result ? @"YES" : @"NO"));
        DLog(@"error: %@", error.description);
    }
}

+ (void)setSessionToken:(NSString *)sessionToken expiration:(NSNumber *)expiration {
    NBSessionInfo *sessionInfo = [[self alloc] init];
    NSError *error = nil;

    // ファイル読み込み
    NSDictionary *dict = [sessionInfo.fileManager loadFromPlist:NBUserPlist error:&error];

    NSMutableDictionary *mdict;
    if (dict) {
        mdict = [dict mutableCopy];
        // 前回分を削除する
        [mdict removeObjectForKey:NBKeySessionToken];
        [mdict removeObjectForKey:NBKeySessionTokenExpiration];
    } else {
        mdict = [NSMutableDictionary dictionary];
    }

    // セッショントークンとセッショントークンの有効期限を更新
    if (sessionToken) {
        mdict[NBKeySessionToken] = sessionToken;
    }
    if (expiration) {
        mdict[NBKeySessionTokenExpiration] = expiration;
    }

    // ファイル保存
    error = nil;
    BOOL result = [sessionInfo.fileManager saveToPlist:NBUserPlist data:mdict error:&error];

    if (!result || error) {
        DLog(@"result: %@", (result ? @"YES" : @"NO"));
        DLog(@"error: %@", error.description);
    }
}

+ (void)clearSessionInfo {
    NBSessionInfo *sessionInfo = [[self alloc] init];
    NSError *error = nil;

    // ファイル削除
    BOOL result = [sessionInfo.fileManager deletePlist:NBUserPlist error:&error];

    if (!result || error) {
        DLog(@"result: %@", (result ? @"YES" : @"NO"));
        DLog(@"error: %@", error.description);
    }
}

- (instancetype)init {
    self = [super init];

    if (self) {
        // NBFileManagerインスタンス取得
        self.fileManager = [NBFileManager sharedManager];
    }

    return self;
}

#pragma mark -
#pragma mark private methods

/**
 *  キー情報取得
 *
 *  キー情報一覧をNSArray型で返却する。
 *
 *  @return キー情報配列
 */
+ (NSArray *)userKeys {
    return @[ @"userId", @"username", @"email", @"created", @"updated" ];
}

@end
