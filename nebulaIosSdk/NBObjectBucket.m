//
//  NBObjectBucket.m
//
//  COPYRIGHT (C) 2014 NEC CORPORATION
//

#import "Headers/NBObjectBucket.h"
#import "Headers/NBQuery.h"
#import "Headers/NBClause.h"
#import "Headers/NBObject.h"
#import "Headers/NBBlocks.h"

#import "NBUtilities.h"
#import "NBRestExecutor.h"
#import "NBURLRequestFactory.h"
#import "NBErrorFactory.h"
#import "Common.h"

@interface NBObjectBucket ()
@property (nonatomic, copy) NSString *bucketName;

@end

@implementation NBObjectBucket

static NSString *const NBKeyResults = @"results";
static NSString *const NBKeyCount = @"count";
static NSString *const NBKeyWhere = @"where";
static NSString *const NBKeyOrder = @"order";
static NSString *const NBKeySkip = @"skip";
static NSString *const NBKeyLimit = @"limit";

static NSString *const NBValueEnableCount = @"1";

@synthesize bucketName;

// 親クラスの指定イニシャライザを override
- (instancetype)init {
    return [self initWithBucketName:@""];
}

#pragma mark -
#pragma mark public methods

// 指定イニシャライザ
- (instancetype)initWithBucketName:(NSString *)name {
    if (self = [super init]) {
        self.bucketName = name;
    }
    return self;
}

- (NBObject *)createObject {
    NBObject *object = [[NBObject alloc] initWithBucketName:self.bucketName];
    return object;
}

- (void)getObjectInBackgroundWithId:(NSString *)objectId block:(NBObjectsBlock)block {
    // callbackを保存
    NBObjectsBlock copyBlock = [block copy];

    // factoryにHttpRequestの生成を要求
    NSError *requestError = nil;
    NSMutableString *apiUrlString = [NSMutableString string];
    [apiUrlString appendFormat:@"%@/%@/%@", NBObjectApiUrl, self.bucketName, objectId];

    NSURLRequest *request =
        [NBURLRequestFactory makeRequestForMethod:NBHTTPMethodGET url:apiUrlString useToken:NBUseSessionTokenOptional error:&requestError];

    // Request作成エラー発生
    if (requestError) {
        dispatch_async(dispatch_get_main_queue(), ^{
            copyBlock(nil, 0, requestError);
        });
        return;
    }

    // RestExecutorの生成
    NBRestExecutor *executor =
        [NBRestExecutor executorWithRequest:request name:@"objectInBackgroundWithId"];
    // 非同期実行要求とBlockの定義
    [executor executeRequestInBackgroundWithBlock:^(NSData *data, NSError *error) {
         NSDictionary *jsonResult = nil;

         // 下位の処理が正常終了している場合は処理続行
         if (!error) {
             jsonResult = [NSJSONSerialization JSONObjectWithData:data options:0 error:&error];
         }

         NSArray *objectArrayFromJson = nil;
         if (!error) {
             NBObject *aNewObject = [self createObjectFromJsonDictionary:jsonResult];
             objectArrayFromJson = @[aNewObject];
         }

         copyBlock(objectArrayFromJson, 0, error);
     }];
}

- (void)queryInBackgroundWithQuery:(NBQuery *)query block:(NBObjectsBlock)block {
    // callbackを保存
    NBObjectsBlock copyBlock = [block copy];

    // factoryにHttpRequestの生成を要求
    NSError *requestError = nil;
    NSMutableString *apiUrlString = [NSMutableString string];
    [apiUrlString appendFormat:@"%@/%@", NBObjectApiUrl, self.bucketName];

    // queryから条件を集めてdictionaryにまとめる
    // リクエストパラメータの作成
    NSDictionary *requestParameters = [self queryParamsWithQuery:query error:&requestError];

    // クエリパラメータ生成失敗
    if (requestError) {
        dispatch_async(dispatch_get_main_queue(), ^{
            copyBlock(nil, 0, requestError);
        });

        return;
    }

    NSURLRequest *request =
        [NBURLRequestFactory makeRequestForMethod:NBHTTPMethodGET url:apiUrlString useToken:NBUseSessionTokenOptional param:requestParameters error:&
         requestError];

    // Request作成エラー発生
    if (requestError) {
        dispatch_async(dispatch_get_main_queue(), ^{
            copyBlock(nil, 0, requestError);
        });

        return;
    }

    // RestExecutorの生成
    NBRestExecutor *executor =
        [NBRestExecutor executorWithRequest:request name:@"queryInBackgroundWithQuery"];
    // 非同期実行要求とBlockの定義
    [executor executeRequestInBackgroundWithBlock:^(NSData *data, NSError *error) {
         NSDictionary *jsonResult = nil;
         if (!error) {
             jsonResult = [NSJSONSerialization JSONObjectWithData:data options:0 error:&error];
         }

         NSArray *nbObjectsArray = nil;
         NSUInteger countFromJson = 0;
         if (!error) {
             // 検索結果をObjectの配列に変換して格納
             NSArray *jsonArray = jsonResult[NBKeyResults];
             nbObjectsArray = [self createObjectArrayFromJsonArray:jsonArray];

             // count要素が存在する場合は格納
             NSNumber *number = jsonResult[NBKeyCount];
             countFromJson = [number intValue];
         }

         copyBlock(nbObjectsArray, countFromJson, error);
     }];
}

#pragma mark -
#pragma mark private method

/**
 *  Queryから検索条件となるDictionaryを取得する
 *
 *  @param query 検索条件を含んだquery
 *
 *  @return queryから生成したリクエストパラメータ
 */
- (NSDictionary *)queryParamsWithQuery:(NBQuery *)query error:(NSError **)error {
    // 条件指定がないパラメータは設定しない
    NSMutableDictionary *queryParams = [NSMutableDictionary dictionary];

    // where
    NBClause *queryClause = query.clause;
    if (queryClause) {
        NSDictionary *clauseDictionary = [queryClause dictionaryValue];

        NSString *whereString = [self jsonFromDictionary:clauseDictionary error:error];
        // エラー発生時は処理中断
        if (*error) {
            return nil;
        }

        if (whereString) {
            queryParams[NBKeyWhere] = whereString;
        }
    }

    // order
    NSArray *queryOrder = [query sortOrder];
    if (queryOrder) {
        NSUInteger counter = 0;
        NSMutableString *orderString = [NSMutableString string];
        // sortの格納順にStringに付与
        for (NSDictionary *sortDictionary in queryOrder) {
            NSArray *keys = [sortDictionary allKeys];

            // order要素の作成
            for (NSString *aKey in keys) {
                if (counter != 0) {
                    // 先頭の要素以外はセパレータ","を追加
                    [orderString appendString:@","];
                }

                BOOL isAscend = [sortDictionary[aKey] boolValue];
                if (!isAscend) {
                    // 降順の場合は"-"を追加
                    [orderString appendString:@"-"];
                }
                // フィールド名追加
                [orderString appendString:aKey];

                counter++;
            }
        }

        if (orderString.length > 0) {
            queryParams[NBKeyOrder] = orderString;
        }
    }

    // skip
    if (query && query.skip >= 0) {
        queryParams[NBKeySkip] = [NSString stringWithFormat:@"%lld", (long long)query.skip];
    }

    // limit
    if (query && query.limit >= -1) {
        queryParams[NBKeyLimit] = [NSString stringWithFormat:@"%lld", (long long)query.limit];
    }

    // count
    if (query.queryCount) {
        queryParams[NBKeyCount] = NBValueEnableCount;
    }

    return queryParams;
}

/**
 *  DictionaryからJSONのStringに変換する
 *  クエリのwhereを生成するために使用する
 *
 *  @param dictionary JSONオブジェクトのdictionary
 *
 *  @return JSONのString
 */
- (NSString *)jsonFromDictionary:(NSDictionary *)dictionary error:(NSError **)error {
    NSData *jsonData = nil;
    NSString *result = nil;

    // JSON Object -> NSData
    jsonData = [NSJSONSerialization dataWithJSONObject:dictionary options:NSJSONWritingPrettyPrinted error:error];
    if (!(*error)) {
        // 文字列に変換して取得
        result = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
    }
    else {
        DLog(@"invalid json parameters : %@", *error);
    }
    return result;
}

/**
 *  JSONオブジェクトのDictionaryからNBObjectを生成する
 *
 *  @param objectDictionary JSONオブジェクトのDictionary
 *
 *  @return パラメータをNBOBjectに変換
 */
- (NBObject *)createObjectFromJsonDictionary:(NSDictionary *)objectDictionary {
    NBObject *object = [self createObject];
    [object setObjectDataWithDictionary:objectDictionary];
    return object;
}

/**
 *  JSON Objectの配列からNBObjectの配列を生成(queryの結果の変換向け)
 *
 *  @param objectJsonArray JSONオブジェクトの配列。各要素はDictionary形式であること。
 *
 *  @return 配列に格納したNBObject
 */
- (NSArray *)createObjectArrayFromJsonArray:(NSArray *)objectJsonArray {
    NSMutableArray *objectArray = [NSMutableArray array];
    for (NSDictionary *aObject in objectJsonArray) {
        NBObject *aNewObject = [self createObjectFromJsonDictionary:aObject];
        if (aNewObject) {
            [objectArray addObject:aNewObject];
        }
    }

    return objectArray;
}

@end
