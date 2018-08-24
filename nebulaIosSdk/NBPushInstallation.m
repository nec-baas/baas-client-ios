//
//  NBPushInstallation.m
//
//  COPYRIGHT (C) 2014 NEC CORPORATION
//

#import <UIKit/UIDevice.h>
#import "Headers/NBPushInstallation.h"
#import "NBURLRequestFactory.h"
#import "NBRestExecutor.h"
#import "NBFileManager.h"
#import "NBErrorFactory.h"
#import "NBUtilities.h"
#import "Common.h"

@interface NBPushInstallation ()
@property (nonatomic) NSString *osType;
@property (nonatomic) NSString *osVersion;
@property (nonatomic) NSString *pushType;
@property (nonatomic) NSNumber *appVersionCode;
@property (nonatomic) NSString *appVersionString;
@property (nonatomic) NSString *installationId;
@property (nonatomic) NSString *owner;
@end

@implementation NBPushInstallation
/**
 *  定数
 */
// JSON Key
// property名は_が付かない(インスタレーションIDは例外)
static NSString * const NBKeyOsType = @"_osType";
static NSString * const NBKeyOsVersion = @"_osVersion";
static NSString * const NBKeyDeviceToken = @"_deviceToken";
static NSString * const NBKeyPushType = @"_pushType";
static NSString * const NBKeyChannels = @"_channels";
static NSString * const NBKeyAppVersionCode = @"_appVersionCode";
static NSString * const NBKeyAppVersionString = @"_appVersionString";
static NSString * const NBKeyAllowedSenders = @"_allowedSenders";
static NSString * const NBKeyInstallationId = @"_id";    // 対応するpropertyはinstallationId
static NSString * const NBKeyOwner = @"_owner";
static NSString * const NBKeyOperatorFullUpdate = @"$full_update";

// Value
static NSString * const NBValueOsType = @"ios";
static NSString * const NBValuePushTypeApns = @"apns";

// URL
static NSString * const NBURLPushInstallations = @"/push/installations";

// プロパティリストファイル名
static NSString * const NBInstallationPlist = @"installation.plist";

#pragma mark -
#pragma mark public methods

- (void)saveInBackgroundWithBlock:(NBPushInstallationBlock)block {
    // blockを保存する(ヒープ領域に移動する)
    NBPushInstallationBlock copyBlock = [block copy];
    NSError *error = nil;

    // キャッシュされたインスタレーションIDと比較
    NBPushInstallation *currentInstallation = [NBPushInstallation currentInstallation];
    if (currentInstallation.installationId && ![currentInstallation.installationId isEqualToString:self.installationId]) {
        // 一致しない場合
        error = [NBErrorFactory makeErrorForCode:NBErrorPreconditionError];
        dispatch_async(dispatch_get_main_queue(), ^{
            copyBlock(nil, error);
        });
        return;
    }

    // リクエストボディ部作成
    NSDictionary *bodyDict = [self createBodyDictionary];

    NSMutableString *apiUrlString = [NSMutableString string];
    [apiUrlString appendFormat:@"%@", NBURLPushInstallations];
    NBHTTPMethod method = NBHTTPMethodPOST;

    if (self.installationId) {
        // インスタレーションIDを保持しているため、完全上書き(full_update)として扱う

        [apiUrlString appendFormat:@"/%@", self.installationId];
        method = NBHTTPMethodPUT;

        // リクエストボディを完全上書き用に更新
        NSMutableDictionary *fullUpdateDict = [NSMutableDictionary dictionary];
        fullUpdateDict[NBKeyOperatorFullUpdate] = bodyDict;
        bodyDict = fullUpdateDict;
    } else {
        // 新規作成として扱う
        // パス、HTTPメソッド、リクエストボディ変更無し
    }

    // JSON Object -> NSData
    NSData *bodyData = [NSJSONSerialization dataWithJSONObject:bodyDict options:NSJSONWritingPrettyPrinted error:&error];
    DLog(@"%@", [[NSString alloc] initWithData:bodyData encoding:NSUTF8StringEncoding]);

    if (error) {
        dispatch_async(dispatch_get_main_queue(), ^{
            copyBlock(nil, error);
        });
        return;
    }

    // URLリクエスト生成
    NSURLRequest *request = [NBURLRequestFactory makeRequestForMethod:method
                             url:apiUrlString
                             useToken:NBUseSessionTokenOptional
                             body:bodyData
                             error:&error];

    if (error) {
        dispatch_async(dispatch_get_main_queue(), ^{
            copyBlock(nil, error);
        });
        return;
    }

    // リクエスト送信
    NBRestExecutor *executor = [NBRestExecutor executorWithRequest:request name:@"saveInBackgroundWithBlock"];
    [executor executeRequestInBackgroundWithBlock:^(NSData *data, NSError *error) {

         if (error.code == 404) {
             // 「404 Not Found」の場合、サーバDBとの不整合をなくすため、キャッシュ情報を削除
             // サーバからのエラーを優先するため、キャッシュ削除で発生したエラーはMaskする
             NSError *deleteError = nil;
             [NBPushInstallation deleteInstallation:&deleteError];
         }

         id jsonObject = nil;
         if (!error) {
             // NSData -> JSON Object
             jsonObject = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableContainers error:&error];
         }

         NBPushInstallation *installation = nil;
         if (!error) {
             installation = [NBPushInstallation pushInstallationFromJson:jsonObject];

             // 上で作成したinstallationをそのままBlockに渡すと、JSONでnull値がそのまま設定されるため、保存後読み出したものを渡す
             // loadInstallation()内でNSNullはnilに置換される

             // キャッシュに保存
             BOOL result = [NBPushInstallation saveInstallation:installation error:&error];

             if (result) {
                 installation = [NBPushInstallation loadInstallation:&error];
             }

             if (error) {
                 installation = nil;
             }
         }

         copyBlock(installation, error);
     }];
}

+ (void)partUpdateInBackgroundWithDictionary:(NSDictionary *)dictionary block:(NBPushInstallationBlock)block {
    NBPushInstallationBlock copyBlock = [block copy];
    NSError *error = nil;

    // キャッシュされたインスタレーション情報を取得
    NBPushInstallation *currentInstallation = [NBPushInstallation currentInstallation];

    // リクエストボディ部作成
    NSMutableDictionary *bodyDict;
    if (dictionary) {
        bodyDict = [dictionary mutableCopy];
    } else {
        bodyDict = [NSMutableDictionary dictionary];
    }

    [NBPushInstallation setValueToBodyDictionary:bodyDict comparedInstallation:currentInstallation];

    // JSON Object -> NSData
    NSData *bodyData = [NSJSONSerialization dataWithJSONObject:bodyDict options:NSJSONWritingPrettyPrinted error:&error];

    if (error) {
        dispatch_async(dispatch_get_main_queue(), ^{
            copyBlock(nil, error);
        });
        return;
    }

    // URLリクエスト生成
    NSURLRequest *request = [NBURLRequestFactory makeRequestForMethod:NBHTTPMethodPUT
                             url:[NBURLPushInstallations stringByAppendingFormat:@"/%@", currentInstallation.installationId]
                             useToken:NBUseSessionTokenOptional
                             body:bodyData
                             error:&error];
    if (error) {
        dispatch_async(dispatch_get_main_queue(), ^{
            copyBlock(nil, error);
        });
        return;
    }

    // リクエスト送信
    NBRestExecutor *executor = [NBRestExecutor executorWithRequest:request name:@"partUpdateInBackgroundWithDictionary"];
    [executor executeRequestInBackgroundWithBlock:^(NSData *data, NSError *error) {

         if (error.code == 404) {
             // 「404 Not Found」の場合、サーバDBとの不整合をなくすため、キャッシュ情報を削除
             // サーバからのエラーを優先するため、キャッシュ削除で発生したエラーはMaskする
             NSError *deleteError = nil;
             [NBPushInstallation deleteInstallation:&deleteError];
         }

         id jsonObject = nil;
         if (!error) {
             // NSData -> JSON Object
             jsonObject = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableContainers error:&error];
         }

         NBPushInstallation *installation = nil;
         if (!error) {
             installation = [NBPushInstallation pushInstallationFromJson:jsonObject];

             // 上で作成したinstallationをそのままBlockに渡すと、JSONでnull値がそのまま設定されるため、保存後読み出したものを渡す
             // loadInstallation()内でNSNullはnilに置換される

             // キャッシュに保存
             BOOL result = [NBPushInstallation saveInstallation:installation error:&error];

             if (result) {
                 installation = [NBPushInstallation loadInstallation:&error];
             }

             if (error) {
                 installation = nil;
             }
         }

         copyBlock(installation, error);
     }];
}

- (void)setDeviceTokenFromData:(NSData *)deviceTokenData {
    // NSData -> NSString
    NSString *deviceTokenString = [self stringFromDeviceTokenData:deviceTokenData];

    self.deviceToken = deviceTokenString;
}

+ (NBPushInstallation *)currentInstallation {
    NSError *error = nil;
    NBPushInstallation *installation = [NBPushInstallation loadInstallation:&error];

    return installation;
}

+ (void)refreshCurrentInstallationInBackgroundWithBlock:(NBPushInstallationBlock)block {
    // blockを保存する(ヒープ領域に移動する)
    NBPushInstallationBlock copyBlock = [block copy];
    NSError *error = nil;

    // キャッシュされたインスタレーション情報を取得(installationIdをパスに設定するため)
    NBPushInstallation *currentInstallation = [self currentInstallation];

    // URLリクエスト生成
    NSURLRequest *request = [NBURLRequestFactory makeRequestForMethod:NBHTTPMethodGET
                             url:[NBURLPushInstallations stringByAppendingFormat:@"/%@", currentInstallation.installationId]
                             useToken:NBUseSessionTokenNotUse
                             error:&error];
    if (error) {
        dispatch_async(dispatch_get_main_queue(), ^{
            copyBlock(nil, error);
        });
        return;
    }

    // リクエスト送信
    NBRestExecutor *executor = [NBRestExecutor executorWithRequest:request name:@"refreshCurrentInstallationInBackgroundWithBlock"];
    [executor executeRequestInBackgroundWithBlock:^(NSData *data, NSError *error) {

         if (error.code == 404) {
             // 「404 Not Found」の場合、サーバDBとの不整合をなくすため、キャッシュ情報を削除
             // サーバからのエラーを優先するため、キャッシュ削除で発生したエラーはMaskする
             NSError *deleteError = nil;
             [NBPushInstallation deleteInstallation:&deleteError];
         }

         id jsonObject = nil;
         if (!error) {
             // NSData -> JSON Object
             jsonObject = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableContainers error:&error];
         }

         NBPushInstallation *installation = nil;
         if (!error) {
             installation = [NBPushInstallation pushInstallationFromJson:jsonObject];

             // 上で作成したinstallationをそのままBlockに渡すと、JSONでnull値がそのまま設定されるため、保存後読み出したものを渡す
             // loadInstallation()内でNSNullはnilに置換される

             // キャッシュに保存
             BOOL result = [NBPushInstallation saveInstallation:installation error:&error];

             if (result) {
                 installation = [NBPushInstallation loadInstallation:&error];
             }

             if (error) {
                 installation = nil;
             }
         }

         copyBlock(installation, error);
     }];
}

- (void)deleteInBackgroundWithBlock:(NBResultBlock)block {
    NBResultBlock copyBlock = [block copy];
    NSError *error = nil;

    // URLリクエスト生成
    NSURLRequest *request = [NBURLRequestFactory makeRequestForMethod:NBHTTPMethodDELETE
                             url:[NBURLPushInstallations stringByAppendingFormat:@"/%@", self.installationId]
                             useToken:NBUseSessionTokenOptional
                             error:&error];
    if (error) {
        dispatch_async(dispatch_get_main_queue(), ^{
            copyBlock(error);
        });
        return;
    }

    // リクエスト送信
    NBRestExecutor *executor = [NBRestExecutor executorWithRequest:request name:@"deleteInBackgroundWithBlock"];
    [executor executeRequestInBackgroundWithBlock:^(NSData *data, NSError *error) {

         if (!error || error.code == 404) {
             NBPushInstallation *currentInstallation = [NBPushInstallation currentInstallation];
             if (currentInstallation.installationId && [currentInstallation.installationId isEqualToString:self.installationId]) {
                 if (!error) {
                     // キャッシュ情報を削除
                     [NBPushInstallation deleteInstallation:&error];
                 } else {
                     // サーバからのエラーを優先するため、キャッシュ削除で発生したエラーはMaskする
                     NSError *deleteError = nil;
                     [NBPushInstallation deleteInstallation:&deleteError];
                 }
             }
         }

         copyBlock(error);
     }];
}

- (instancetype)init {
    self = [super init];

    if (self) {
        self.osType = nil;
        self.osVersion = nil;
        self.deviceToken = nil;
        self.pushType = nil;
        self.channels = nil;
        self.appVersionCode = nil;
        self.appVersionString = nil;
        self.allowedSenders = @[@"g:anonymous"];
        self.options = nil;
        self.installationId = nil;
        self.owner = nil;
    }

    return self;
}

#pragma mark -
#pragma mark private methods

/**
 *  リクエストボディ部作成
 *
 *  クラスオブジェクトをリクエストボディデータとして設定する。
 *
 *  @return 作成したリクエストボディ
 */
- (NSDictionary *)createBodyDictionary {
    NSNull *nul = [NSNull null];

    // 任意のKey-Valueをリクエストボディに設定
    NSMutableDictionary *mdict;
    if (self.options) {
        mdict = [self.options mutableCopy];
    } else {
        mdict = [NSMutableDictionary dictionary];
    }

    // write可能なクラスオブジェクトをNSDictionaryに変換
    // nilオブジェクトはNSNullに変換される
    NSDictionary *dict = [self dictionaryWithValuesForKeys:[self writableKeys]];

    // クラスオブジェクトをリクエストボディに設定
    for (id key in dict) {
        NSString *jsonKey = [@"_" stringByAppendingString:key];

        if (dict[key] && dict[key] != nul) {
            // NSNullを省く
            mdict[jsonKey] = dict[key];
        }
    }

    // readonlyオブジェクト分をリクエストボディに設定
    [NBPushInstallation setValueToBodyDictionary:mdict comparedInstallation:nil];

    return mdict;
}

/**
 *  リクエストボディ設定
 *
 *  リクエストボディにライブラリ内で補完する値を設定する。
 *
 *  @param bodyDictionary       リクエストボディ
 *  @param comparedInstallation 比較対象のインスタレーション(新規登録/完全上書き更新の場合はnil)
 */
+ (void)setValueToBodyDictionary:(NSMutableDictionary *)bodyDictionary comparedInstallation:(NBPushInstallation *)comparedInstallation {
    // comparedInstallationがnil => 新規登録/完全上書き更新の場合はリクエストボディに設定
    // comparedInstallationがnilでない => カレントと比較し、一致しなかった場合のみリクエストボディに設定
    if (!bodyDictionary) {
        return;
    }

    if (!comparedInstallation || ![comparedInstallation.osType isEqualToString:NBValueOsType]) {
        bodyDictionary[NBKeyOsType] = NBValueOsType;
    }

    NSString *osVersion = [UIDevice currentDevice].systemVersion;
    if (!comparedInstallation || ![comparedInstallation.osVersion isEqualToString:osVersion]) {
        bodyDictionary[NBKeyOsVersion] = osVersion;
    }

    if (!comparedInstallation || ![comparedInstallation.pushType isEqualToString:NBValuePushTypeApns]) {
        bodyDictionary[NBKeyPushType] = NBValuePushTypeApns;
    }

    NSNumber *appVersionCode = [NBPushInstallation getAppVersionCode];
    if (!comparedInstallation || ![comparedInstallation.appVersionCode isEqualToNumber:appVersionCode]) {
        bodyDictionary[NBKeyAppVersionCode] = appVersionCode;
    }

    NSString *appVersionString = [[NSBundle mainBundle] infoDictionary][@"CFBundleShortVersionString"];
    if (!comparedInstallation || ![comparedInstallation.appVersionString isEqualToString:appVersionString]) {
        if (appVersionString && ![appVersionString isEqual:[NSNull null]]) {
            bodyDictionary[NBKeyAppVersionString] = appVersionString;
        }
    }
}

/**
 *  JSONからPushInstallationインスタンス生成
 *
 *  レスポンスボディ(JSON)からPushInstallationインスタンスを生成する。
 *
 *  @param json レスポンスボディ(JSON)
 *
 *  @return PushInstallationインスタンス
 */
+ (NBPushInstallation *)pushInstallationFromJson:(NSDictionary *)json {
    NBPushInstallation *installation = [NBPushInstallation new];
    NSMutableDictionary *mdict = [NSMutableDictionary dictionary];

    for (NSString *aKey in json) {
        id aValue = json[aKey];

        if ([aKey isEqualToString:NBKeyOsType]) {
            installation.osType = aValue;
        } else if ([aKey isEqualToString:NBKeyOsVersion]) {
            installation.osVersion = aValue;
        } else if ([aKey isEqualToString:NBKeyDeviceToken]) {
            installation.deviceToken = aValue;
        } else if ([aKey isEqualToString:NBKeyPushType]) {
            installation.pushType = aValue;
        } else if ([aKey isEqualToString:NBKeyChannels]) {
            installation.channels = aValue;
        } else if ([aKey isEqualToString:NBKeyAppVersionCode]) {
            installation.appVersionCode = aValue;
        } else if ([aKey isEqualToString:NBKeyAppVersionString]) {
            installation.appVersionString = aValue;
        } else if ([aKey isEqualToString:NBKeyAllowedSenders]) {
            installation.allowedSenders = aValue;
        } else if ([aKey isEqualToString:NBKeyInstallationId]) {
            installation.installationId = aValue;
        } else if ([aKey isEqualToString:NBKeyOwner]) {
            installation.owner = aValue;
        } else {
            // 任意のプロパティ
            mdict[aKey] = aValue;
        }
    }

    if ([mdict count] > 0) {
        // 任意のプロパティが存在する場合
        installation.options = mdict;
    }

    return installation;
}

/**
 *  インスタレーション情報読み出し
 *
 *  キャッシュから読み出したインスタレーション情報を返す。
 *  インスタレーション情報がキャッシュに存在しない場合は、新しく生成したインスタンスを返す。
 *
 *  @param error エラー内容
 *
 *  @return インスタレーション情報
 */
+ (NBPushInstallation *)loadInstallation:(NSError **)error {
    NBPushInstallation *installation = [NBPushInstallation new];

    // ファイル読み込み
    NBFileManager *fileManager = [NBFileManager sharedManager];
    NSDictionary *dict = [fileManager loadFromPlist:NBInstallationPlist error:error];

    if (*error || !dict) {
        return installation;
    }

    // NSDictionaryをオブジェクトに変換する
    // NSNullはnilに変換される
    // 存在しないkeyはnewした時の値(=nil)となる
    [installation setValuesForKeysWithDictionary:dict];
    return installation;
}

/**
 *  インスタレーション情報保存
 *
 *  インスタレーション情報をキャッシュに保存する。
 *
 *  @param installation 保存するインスタレーション情報
 *  @param error        エラー内容
 *
 *  @return 処理結果（YES:成功/NO:失敗）
 */
+ (BOOL)saveInstallation:(NBPushInstallation *)installation error:(NSError **)error {
    // オブジェクトをNSDictionaryに変換する
    // nilオブジェクトはNSNullに変換される
    NSDictionary *dict = [installation dictionaryWithValuesForKeys:[installation allKeys]];

    // ファイルに保存
    NBFileManager *fileManager = [NBFileManager sharedManager];
    BOOL result = [fileManager saveToPlist:NBInstallationPlist data:dict error:error];

    return result;
}

/**
 *  インスタレーション情報削除
 *
 *  インスタレーション情報をキャッシュから削除する。
 *
 *  @param error エラー内容
 *
 *  @return 処理結果（YES:成功/NO:失敗）
 */
+ (BOOL)deleteInstallation:(NSError **)error {
    // ファイル削除
    NBFileManager *fileManager = [NBFileManager sharedManager];
    BOOL result = [fileManager deletePlist:NBInstallationPlist error:error];

    return result;
}

/**
 *  アプリケーションのバージョンコード取得
 *
 *  CFBundleVersion値を取得し、以下ロジックにてNSNumberに変換する。
 *  (1) .(ピリオド)区切りの数値は、下記のように変換する。
 *      x.y.z => x * 1,000,000 + y * 1,000 + z
 *      x.y => x * 1,000,000 + y * 1,000
 *      x => x * 1,000,000
 *  (2)0～9以外の文字が含まれる場合は、その区切りは0とみなす。
 *  (3)3番目以降の区切りは無視する。
 *
 *  @return アプリケーションのバージョンコード
 */
+ (NSNumber *)getAppVersionCode {
    NSString *versionString = [[NSBundle mainBundle] infoDictionary][@"CFBundleVersion"];

    if ([versionString isEqual:[NSNull null]] || ![versionString length]) {
        // NSNull値 or nil or 空文字の場合
        return @0;
    }

    // .(ピリオド)で区切る
    NSArray *versionArray = [versionString componentsSeparatedByString:@"."];

    long long version = 0;

    if (versionArray.count > 0 && [NBUtilities isDigit:versionArray[0]]) {
        version += [versionArray[0] longLongValue] * 1000000;
    }
    if (versionArray.count > 1 && [NBUtilities isDigit:versionArray[1]]) {
        version += [versionArray[1] longLongValue] * 1000;
    }
    if (versionArray.count > 2 && [NBUtilities isDigit:versionArray[2]]) {
        version += [versionArray[2] longLongValue];
    }

    return @(version);
}

/**
 *  文字列DeviceToken取得
 *
 *  16進数で表現した文字列のDeviceTokenを取得する。
 *
 *  @param deviceToken deviceToken(NSData型)
 *
 *  @return 16進数表記のDeviceToken
 */
- (NSString *)stringFromDeviceTokenData:(NSData *)deviceToken {
    const char *data = [deviceToken bytes];
    NSMutableString *token = [NSMutableString string];

    for (int i = 0; i < [deviceToken length]; i++)
        [token appendFormat:@"%02.2hhX", data[i]];

    return [token copy];
}

/**
 *  書き込み可能要素キー取得
 *
 *  独自クラスの要素として取り扱う書き込み可能なプロパティ名の一覧をNSArray型で返却する。
 *
 *  @return 要素キーを含めた配列
 */
- (NSArray *)writableKeys {
    return @[@"deviceToken", @"channels", @"allowedSenders"];
}

/**
 *  要素キー取得
 *
 *  独自クラスの要素として取り扱うプロパティ名の一覧をNSArray型で返却する。
 *
 *  @return 要素キーを含めた配列
 */
- (NSArray *)allKeys {
    return @[@"osType", @"osVersion", @"deviceToken", @"pushType", @"channels", @"appVersionCode", @"appVersionString", @"allowedSenders",
             @"options", @"installationId", @"owner"];
}

- (void)setValue:(id)value forUndefinedKey:(NSString *)key {
    DLog(@"Error: setting unknown key: %@ with data: %@", key, value);
}

@end
