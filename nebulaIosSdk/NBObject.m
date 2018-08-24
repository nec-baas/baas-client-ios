//
//  NBObject.m
//
//  COPYRIGHT (C) 2014 NEC CORPORATION
//


#import "Headers/NBObject.h"
#import "Headers/NBAcl.h"

#import "NBUtilities.h"
#import "NBRestExecutor.h"
#import "NBURLRequestFactory.h"
#import "NBErrorFactory.h"
#import "Common.h"

@interface NBObject ()
@property (nonatomic) NSString *bucket;
@property (nonatomic) NSString *objectId;
@property (nonatomic) NSDate *created;
@property (nonatomic) NSDate *updated;
@property (nonatomic) NSString *etag;

/**
 *  ユーザ設定のKey-Valueを格納
 */
@property (nonatomic) NSMutableDictionary *objectData;

@end

@implementation NBObject

static NSString *const NBKeyEtag = @"etag";
static NSString *const NBKeyAcl = @"ACL";
static NSString *const NBKeyObjectId = @"_id";
static NSString *const NBKeyCreatedAt = @"createdAt";
static NSString *const NBKeyUpdatedAt = @"updatedAt";

static NSString *const NBKeyOperatorFullUpdate = @"$full_update";

@synthesize acl;
@synthesize bucket;
@synthesize objectId;
@synthesize created;
@synthesize updated;
@synthesize etag;
@synthesize objectData;


#pragma mark -
#pragma mark public methods

+ (instancetype)objectWithBucketName:(NSString *)bucketName {
    id instance = [[[self class] alloc] initWithBucketName:bucketName];

    return instance;
}

/**
 *  NBObjectをBucket名無指定で初期化を行う
 *
 *  @return Bucket名にnilを指定したNBObjectのインスタンス
 */
- (instancetype)init {
    return [self initWithBucketName:nil];
}

- (instancetype)initWithBucketName:(NSString *)bucketName {
    if (self = [super init]) {
        // bucket名は書き換え不可
        self.bucket = [bucketName copy];
        self.objectData = [NSMutableDictionary dictionary];
    }
    return self;
}

- (id)objectForKey:(NSString *)key {
    return self.objectData[key];
}

- (void)setObject:(id)object forKey:(NSString *)key {
    self.objectData[key] = object;
}

- (NSArray *)allKeys {
    return [self.objectData allKeys];
}

- (void)removeObjectForKey:(NSString *)key {
    [self.objectData removeObjectForKey:key];
}

- (void)deleteInBackgroundWithBlock:(NBResultBlock)block {
    // callbackで使用するためにBlockを保存
    NBResultBlock copyBlock = [block copy];

    // Requestの生成
    NSError *requestError = nil;
    NSMutableString *apiUrlString = [NSMutableString string];
    [apiUrlString appendFormat:@"%@/%@/%@", NBObjectApiUrl, self.bucket, self.objectId];

    // Request Parameters
    NSDictionary *etagParam = nil;
    if (self.etag) {
        etagParam = @{ NBKeyEtag : self.etag };
    }
    NSURLRequest *request =
        [NBURLRequestFactory makeRequestForMethod:NBHTTPMethodDELETE url:apiUrlString useToken:NBUseSessionTokenOptional param:etagParam error:&
         requestError];

    // Request作成エラー発生
    if (requestError) {
        dispatch_async(dispatch_get_main_queue(), ^{
            copyBlock(requestError);
        });
        return;
    }

    // callback用の情報を保存
    NBRestExecutor *executor = [NBRestExecutor executorWithRequest:request name:@"deleteInBackgroundWithBlock"];

    [executor executeRequestInBackgroundWithBlock:^(NSData *data, NSError *error) {
         if (!error) {
             // 削除に成功したためobjectIdを消去して使用できない状態とする
             self.objectId = nil;
         }
         // 通常の削除にはbodyは無し
         // deletemarkをつけた場合はJSON dataが入る。(3Q対象外なので考慮しない)

         copyBlock(error);
     }];
}

- (void)saveInBackgroundWithBlock:(NBObjectsBlock)block {
    // callbackで使用するためにBlockを保存
    NBObjectsBlock copyBlock = [block copy];

    // Bodyの作成
    NSMutableDictionary *bodyDict = [self createBodyDictionary:self.objectData];
    if (!bodyDict) {
        // ステータスエラー
        dispatch_async(dispatch_get_main_queue(), ^{
            NSError *localError = [NBErrorFactory makeErrorForCode:NBErrorPreconditionError];
            copyBlock(nil, 0, localError);
        });
        return;
    }

    // ACLがあればbodyに追加
    if (self.acl) {
        NSDictionary *aclDictionary = [self.acl entriesDictionary];
        bodyDict[NBKeyAcl] = aclDictionary;
    }

    // Requestに設定するパラメータの生成
    NSError *requestError = nil;
    NSMutableString *apiUrlString = [NSMutableString string];
    NBHTTPMethod method = 0;
    NBUseSessionToken useSessionToken = NBUseSessionTokenOptional;
    NSDictionary *requestParameter = nil;

    // Request URL (fullupdate/create共通部分のみ作成)
    [apiUrlString appendFormat:@"%@/%@", NBObjectApiUrl, self.bucket];

    if (self.etag) {
        // etagを保持している=サーバにデータがあるため、fullUpdateとして扱う
        // URLをfullupdate用に追記ObjectIdを追記
        [apiUrlString appendFormat:@"/%@", self.objectId];

        method = NBHTTPMethodPUT;
        // Request Parameters
        requestParameter = @{ NBKeyEtag : self.etag };
        // Request BodyをFullUpdate用に更新
        NSMutableDictionary *fullUpdateDict = [NSMutableDictionary dictionary];
        fullUpdateDict[NBKeyOperatorFullUpdate] = bodyDict;
        // 作成し直したbodyに置き換え
        bodyDict = fullUpdateDict;
    }
    else {
        // etagがないので新規作成と判断
        method = NBHTTPMethodPOST;
        // Request Parameter: セッショントークンは3Qでは設定しない
        //Request bodyは作成済みのため処理なし
    }

    // JSON Object -> NSData
    NSData *bodyJsonData = [NSJSONSerialization dataWithJSONObject:bodyDict options:NSJSONWritingPrettyPrinted error:&requestError];

    if (requestError) {
        dispatch_async(dispatch_get_main_queue(), ^{
            copyBlock(nil, 0, requestError);
        });
        return;
    }

    // requestの生成
    NSURLRequest *request =
        [NBURLRequestFactory makeRequestForMethod:method url:apiUrlString useToken:useSessionToken param:requestParameter body:bodyJsonData error:&
         requestError];

    if (requestError) {
        dispatch_async(dispatch_get_main_queue(), ^{
            copyBlock(nil, 0, requestError);
        });
        return;
    }

    // 処理要求
    NBRestExecutor *executor = [NBRestExecutor executorWithRequest:request name:@"saveInBackgroundWithBlock"];

    [executor executeRequestInBackgroundWithBlock:^(NSData *data, NSError *error) {
         NSMutableDictionary *jsonObject = nil;
         NSMutableArray *objectsArray = nil;
         if (!error) {
             // デシリアライズ
             jsonObject = [NSJSONSerialization JSONObjectWithData:data options:0 error:&error];
         }
         if (!error) {
             // 自分自身のオブジェクトに処理結果を反映
             [self setObjectDataWithDictionary:jsonObject];

             // callback用のデータを格納
             objectsArray = [NSMutableArray array];
             // 情報更新した自分自身のインスタンスを代入
             [objectsArray addObject:self];
         }
         copyBlock(objectsArray, 0, error);
     }];
}

- (void)partUpdateInBackgroundWithDictionary:(NSDictionary *)dictionary block:(NBObjectsBlock)block {
    // callback用の情報を保存
    NBObjectsBlock copyBlock = [block copy];

    if (!dictionary) {
        // パラメータエラー
        dispatch_async(dispatch_get_main_queue(), ^{
            NSError *localError = [NBErrorFactory makeErrorForCode:NBErrorInvalidArgumentError];
            copyBlock(nil, 0, localError);
        });
        return;
    }

    // Bodyの作成
    NSMutableDictionary *bodyDict = [self createBodyDictionary:dictionary];
    if (!bodyDict) {
        // ステータスエラー
        dispatch_async(dispatch_get_main_queue(), ^{
            NSError *localError = [NBErrorFactory makeErrorForCode:NBErrorPreconditionError];
            copyBlock(nil, 0, localError);
        });
        return;
    }

    NSData *bodyJsonData = nil;
    NSError *requestError = nil;
    // JSON ObjectをNSDataへ変換可能かどうかをチェック
    // JSON Object -> NSData
    bodyJsonData = [NSJSONSerialization dataWithJSONObject:bodyDict options:NSJSONWritingPrettyPrinted error:&requestError];

    if (requestError) {
        dispatch_async(dispatch_get_main_queue(), ^{
            copyBlock(nil, 0, requestError);
        });
        return;
    }

    // Requestに設定するパラメータの生成
    NSMutableString *apiUrlString = [NSMutableString string];
    [apiUrlString appendFormat:@"%@/%@/%@", NBObjectApiUrl, self.bucket, self.objectId];

    NBHTTPMethod method = NBHTTPMethodPUT;
    NBUseSessionToken useSessionToken = NBUseSessionTokenOptional;
    NSDictionary *requestParameter = nil;
    if (self.etag) {
        requestParameter = @{ NBKeyEtag : self.etag };
    }

    // requestの生成
    NSURLRequest *request =
        [NBURLRequestFactory makeRequestForMethod:method url:apiUrlString useToken:useSessionToken param:requestParameter body:bodyJsonData error:&
         requestError];

    if (requestError) {
        dispatch_async(dispatch_get_main_queue(), ^{
            copyBlock(nil, 0, requestError);
        });
        return;
    }

    NBRestExecutor *executor = [NBRestExecutor executorWithRequest:request name:@"partUpdateInBackgroundWithDictionary"];

    [executor executeRequestInBackgroundWithBlock:^(NSData *data, NSError *error) {
         NSMutableDictionary *jsonObject = nil;
         NSMutableArray *objectsArray = nil;
         if (!error) {
             // デシリアライズ
             jsonObject = [NSJSONSerialization JSONObjectWithData:data options:0 error:&error];
         }
         if (!error) {
             // 自分自身のオブジェクトに応答を反映
             [self setObjectDataWithDictionary:jsonObject];

             // callback用のデータを格納
             objectsArray = [NSMutableArray array];
             // 情報更新した自分自身のインスタンスを代入
             [objectsArray addObject:self];
         }
         copyBlock(objectsArray, 0, error);
     }];
}

- (NSDictionary *)dictionaryValue {
    return [NSDictionary dictionaryWithDictionary:self.objectData];
}

- (void)setObjectDataWithDictionary:(NSDictionary *)dictionary {

    // 既存値を初期化
    self.objectData = [NSMutableDictionary dictionary];

    for (NSString *aKey in dictionary) {
        id aValue = dictionary[aKey];

        // 予約語の情報はobjectData側には反映しない
        // 予約語の情報はプロパティ経由で参照可能
        if ([NBKeyObjectId isEqualToString:aKey]) {
            self.objectId = aValue;
        }
        else if ([NBKeyCreatedAt isEqualToString:aKey]) {
            NSString *date = aValue;
            self.created = [NBUtilities dateWithString:date];
        }
        else if ([NBKeyUpdatedAt isEqualToString:aKey]) {
            NSString *date = aValue;
            self.updated = [NBUtilities dateWithString:date];
        }
        else if ([NBKeyAcl isEqualToString:aKey]) {
            NBAcl *aclFromJson = [[NBAcl alloc] init];
            [aclFromJson setEntriesDictionary:aValue];
            self.acl = aclFromJson;
        }
        else if ([NBKeyEtag isEqualToString:aKey]) {
            self.etag = aValue;
        }
        else {
            self.objectData[aKey] = aValue;
        }
    }
}

- (void)setObject:(id)obj forKeyedSubscript:(NSString*)key {
    [self setObject:obj forKey:key];
}

- (id)objectForKeyedSubscript:(NSString*)key {
    return [self objectForKey:key];
}

#pragma mark -
#pragma mark private methods

/**
 *  ユーザ設定のKey-Valueのフィールドを確認
 *
 *  @return フィールド文字列チェック済みのdictionary。
 *          情報が設定されていない場合も空のdictionaryを返却する。
 *          フィールド名に問題がある場合にはnilを返却する。
 */
- (NSMutableDictionary *)createBodyDictionary:(NSDictionary *)dictionary {
    NSMutableDictionary *result = [NSMutableDictionary dictionary];
    NSArray *keyArray = [dictionary allKeys];
    for (NSString *aKey in keyArray) {
        if ([NBUtilities checkFieldNameWithString:aKey]) {
            id aValue = dictionary[aKey];

            if (aValue) {
                result[aKey] = aValue;
            }
        }
        else {
            DLog(@"invalid key name detected: %@", aKey);

            // チェック結果不正の場合は処理を打ち切る
            result = nil;
            break;
        }
    }

    return result;
}

@end
