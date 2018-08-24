//
//  NBFile.m
//
//  COPYRIGHT (C) 2014 NEC CORPORATION
//


#import "Headers/NBFile.h"
#import "Headers/NBAcl.h"

#import "NBUtilities.h"
#import "NBRestExecutor.h"
#import "NBURLRequestFactory.h"
#import "NBErrorFactory.h"
#import "NBURLSession.h"

@interface NBFile ()
@property (nonatomic) NSString *bucketName;
@property (nonatomic) NSString *objectId;
@property (nonatomic) NSDate *created;
@property (nonatomic) NSDate *updated;

@property (nonatomic) long long contentLength;
@property (nonatomic) NSString *publicUrl;

@end

@implementation NBFile

/**
 *  ファイルアップロードタイプ
 */
typedef NS_ENUM (NSInteger,NBFileUploadType){
    /**
     *  新規アップロード
     */
    NBFileUploadCreate = 0,
    /**
     *  更新アップロード
     */
    NBFileUploadUpdate
};

/**
 *  ファイル公開設定
 */
typedef NS_ENUM (NSInteger,NBFilePublishingType){
    /**
     *  非公開
     */
    NBFilePublishingDisabled = 0,
    /**
     *  公開
     */
    NBFilePublishingEnabled
};

// Key
static NSString *const NBFileKeyContentTypeHeader = @"Content-Type";
static NSString *const NBFileKeyContentTypeBody = @"contentType";
static NSString *const NBFileKeyAclHeader = @"X-ACL";
static NSString *const NBFileKeyAclBody = @"ACL";
static NSString *const NBFileKeyFilename = @"filename";
static NSString *const NBFileKeyLength = @"length";
static NSString *const NBFileKeyMetaEtag = @"metaETag";
static NSString *const NBFileKeyFileEtag = @"fileETag";
static NSString *const NBFileKeyCreated = @"createdAt";
static NSString *const NBFileKeyUpdated = @"updatedAt";
static NSString *const NBFileKeyPublicUrl = @"publicUrl";
static NSString *const NBFileKeyId = @"_id";
static NSString *const NBFileKeyCacheDisabled = @"cacheDisabled";
static NSString *const NBFileKeyDeleteMark = @"_deleted";

static NSString *const NBFileKeyResultMetaData = @"metaData";
static NSString *const NBFileKeyResultReasonCode = @"reasonCode";
static NSString *const NBFileKeyResultDetail = @"detail";
static NSString *const NBFileKeyReasonCodeEtagMismatch = @"etag_mismatch";

// URL
static NSString *const NBFileURLPublish = @"publish";
static NSString *const NBFileURLMeta = @"meta";

@synthesize bucketName;
@synthesize objectId;
@synthesize created;
@synthesize updated;

@synthesize acl;
@synthesize etag;
@synthesize contentType;
@synthesize fileEtag;
@synthesize fileName;

@synthesize contentLength;
@synthesize publicUrl;

#pragma mark - public methods

+ (instancetype)objectWithBucketName:(NSString *)bucketName {
    id instance = [[[self class] alloc] initWithBucketName:bucketName];

    return instance;
}

/**
 *  Bucket名無指定で初期化を行う
 *
 *  @return Bucket名にnilを指定したNBFileのインスタンス
 */
- (instancetype)init {
    return [self initWithBucketName:nil];
}

- (instancetype)initWithBucketName:(NSString *)name {
    if (self = [super init]) {
        // bucket名は書き換え不可
        self.bucketName = [name copy];
    }
    return self;
}

- (void)uploadNewFileInBackgroundWithURL:(NSURL*)url resultBlock:(NBFilesBlock)resultBlock progressBlock:(NBFileProgressBlock)
    progressBlock {

    [self executeUploadingFileInBackgroundWithType:(NBFileUploadType)NBFileUploadCreate
     url:url
     resultBlock:resultBlock
     progressBlock:progressBlock];
}

- (void)uploadNewFileInBackgroundWithData:(NSData*)data resultBlock:(NBFilesBlock)resultBlock progressBlock:(NBFileProgressBlock)
    progressBlock {

    NSError *error = nil;

    [self executeUploadingFileInBackgroundWithType:(NBFileUploadType)NBFileUploadCreate
     url:[NBURLSession createTemporaryFileWithData:data error:&error ]
     resultBlock:resultBlock
     progressBlock:progressBlock];

}


- (void)downloadFileInBackgroundWithURL:(NSURL*)url downloadBlock:(NBFileDownloadBlock)downloadBlock progressBlock:(NBFileProgressBlock)
    progressBlock {

    // callbackで使用するためにBlockを保存
    NBFileDownloadBlock downloadBlockCopy = [downloadBlock copy];
    NBFileProgressBlock progressBlockCopy = [progressBlock copy];

    // Request
    NSError *requestError = nil;
    NBHTTPMethod method = NBHTTPMethodGET;
    NBUseSessionToken useSessionToken = NBUseSessionTokenOptional;

    // Request URL
    NSMutableString *apiUrlString = [NSMutableString string];
    [apiUrlString appendFormat:@"%@/%@/%@", NBFileApiUrl, self.bucketName, [NBUtilities encodeURI:self.fileName]];

    NSURLRequest *request =
        [NBURLRequestFactory makeRequestForMethod:method
         url:apiUrlString
         useToken:useSessionToken
         error:&requestError];

    if (requestError) {
        dispatch_async(dispatch_get_main_queue(), ^{
            downloadBlockCopy(nil, requestError);
        });
        return;
    }

    // execute
    NBRestExecutor *executor = [NBRestExecutor executorWithRequest:request name:@"downloadFileInBackgroundWithPath"];
    [executor executeDownloadRequestInBackgroundWithURL:url block:^(NSURL *url, NSError *error) {
         downloadBlockCopy(url, error);
     } progressBlock:^(int64_t transferred, int64_t expected) {
         if (progressBlockCopy) progressBlockCopy(transferred, expected);
     }];
}

- (void)uploadUpdateFileInBackgroundWithURL:(NSURL*)url resultBlock:(NBFilesBlock)resultBlock progressBlock:(NBFileProgressBlock)
    progressBlock {

    [self executeUploadingFileInBackgroundWithType:(NBFileUploadType)NBFileUploadUpdate
     url:url
     resultBlock:resultBlock
     progressBlock:progressBlock];
}

- (void)uploadUpdateFileInBackgroundWithData:(NSData*)data resultBlock:(NBFilesBlock)resultBlock progressBlock:(NBFileProgressBlock)
    progressBlock {

    [self executeUploadingFileInBackgroundWithType:(NBFileUploadType)NBFileUploadUpdate
     url:[NBURLSession createTemporaryFileWithData:data error:nil]
     resultBlock:resultBlock
     progressBlock:progressBlock];
}

- (void)updateFileInBackgroundWithFilename:(NSString*)name block:(NBFilesBlock)block {

    // callbackで使用するためにBlockを保存
    NBFilesBlock copyBlock = [block copy];


    // Request
    NSError *requestError = nil;
    NBHTTPMethod method = NBHTTPMethodPUT;
    NBUseSessionToken useSessionToken = NBUseSessionTokenOptional;
    NSMutableDictionary *requestParam = [NSMutableDictionary dictionary];

    // URL
    NSMutableString *apiUrlString = [NSMutableString string];
    [apiUrlString appendFormat:@"%@/%@/%@/%@", NBFileApiUrl, self.bucketName, [NBUtilities encodeURI:name], NBFileURLMeta];

    // Request Parameters
    if (self.etag) {
        requestParam[NBFileKeyMetaEtag] = self.etag;
    }

    // Requset Body
    NSMutableDictionary *bodyDict = [NSMutableDictionary dictionary];
    if (self.fileName) {
        bodyDict[NBFileKeyFilename] = self.fileName;
    }
    if (self.contentType) {
        bodyDict[NBFileKeyContentTypeBody] = self.contentType;
    }
    if (self.acl) {
        bodyDict[NBFileKeyAclBody] = [self.acl entriesDictionary];
    }
    // cacheDisabled unsupport

    // JSON Object -> NSData
    NSData *bodyJsonData = [NSJSONSerialization dataWithJSONObject:bodyDict options:NSJSONWritingPrettyPrinted error:&requestError];
    if (requestError) {
        dispatch_async(dispatch_get_main_queue(), ^{
            copyBlock(nil, requestError);
        });
        return;
    }

    NSURLRequest *request =
        [NBURLRequestFactory makeRequestForMethod:method url:apiUrlString useToken:useSessionToken param:requestParam body:bodyJsonData error:&
         requestError];
    if (requestError) {
        dispatch_async(dispatch_get_main_queue(), ^{
            copyBlock(nil,requestError);
        });
        return;
    }


    NBRestExecutor *executor = [NBRestExecutor executorWithRequest:request name:@"updateFileInBackgroundWithFilename"];

    [executor executeRequestInBackgroundWithBlock:^(NSData *data, NSError *error) {

         NSMutableDictionary *jsonDict = nil;
         NSMutableArray *resultArray = nil;

         if (error) {
             copyBlock(resultArray, error);
             return;
         }

         jsonDict = [NSJSONSerialization JSONObjectWithData:data options:0 error:&error];

         if (jsonDict)  {
             // NBFile作る
             NBFile * aFile = [NBFile objectWithBucketName:self.bucketName];
             [aFile setPropertiesWithDictionary:jsonDict];

             // NBFileをArrayへ格納
             resultArray = [NSMutableArray array];
             [resultArray addObject:aFile];

         }
         copyBlock(resultArray, error);

     }];


}

- (void)deleteFileInBackgroundWithBlock:(NBFilesBlock)block {
    // callbackで使用するためにBlockを保存
    NBFilesBlock copyBlock = [block copy];

    // Requestの生成
    NSError *requestError = nil;
    NBHTTPMethod method = NBHTTPMethodDELETE;
    NBUseSessionToken useSessionToken = NBUseSessionTokenOptional;
    NSMutableDictionary *requestParam = [NSMutableDictionary dictionary];

    // URL
    NSMutableString *apiUrlString = [NSMutableString string];
    [apiUrlString appendFormat:@"%@/%@/%@", NBFileApiUrl, self.bucketName, [NBUtilities encodeURI:self.fileName]];

    // Request Parameters
    if (self.etag) {
        requestParam[NBFileKeyMetaEtag] = self.etag;
    }
    if (self.fileEtag) {
        requestParam[NBFileKeyFileEtag] = self.fileEtag;
    }
    // deleteMark unsupport

    NSURLRequest *request =
        [NBURLRequestFactory makeRequestForMethod:method url:apiUrlString useToken:useSessionToken param:requestParam error:&
         requestError];

    // Request作成エラー発生
    if (requestError) {
        dispatch_async(dispatch_get_main_queue(), ^{
            copyBlock(nil,requestError);
        });
        return;
    }

    // callback用の情報を保存
    NBRestExecutor *executor = [NBRestExecutor executorWithRequest:request name:@"deleteFileInBackgroundWithBlock"];

    [executor executeRequestInBackgroundWithBlock:^(NSData *data, NSError *error) {

         NSMutableDictionary *jsonDict = nil;
         NSMutableArray *resultArray = nil;

         if (error) {
             copyBlock(resultArray, error);
             return;
         }

         jsonDict = [NSJSONSerialization JSONObjectWithData:data options:0 error:&error];

         if (jsonDict && ([jsonDict allKeys].count != 0))  {
             // NBFile作る
             NBFile * aFile = [NBFile objectWithBucketName:self.bucketName];
             [aFile setPropertiesWithDictionary:jsonDict];

             // NBFileをArrayへ格納
             resultArray = [NSMutableArray array];
             [resultArray addObject:aFile];
         }

         copyBlock(resultArray, error);

     }];
}

- (void)enablePublishFileInBackgroundWithBlock:(NBFilesBlock)block {
    [self executePublishingFileInBackgroundWithType:NBFilePublishingEnabled block:block];
}

- (void)disablePublishFileInBackgroundWithBlock:(NBFilesBlock)block {
    [self executePublishingFileInBackgroundWithType:NBFilePublishingDisabled block:block];
}

- (void)setPropertiesWithDictionary:(NSDictionary *)dictionary {

    for (NSString *aKey in dictionary) {
        id aValue = dictionary[aKey];

        if ([NBFileKeyId isEqualToString:aKey]) { // _id
            self.objectId = aValue;
        }
        else if ([NBFileKeyFilename isEqualToString:aKey]) { // filename
            self.fileName = aValue;
        }
        else if ([NBFileKeyContentTypeBody isEqualToString:aKey]) { // contentType
            self.contentType = aValue;
        }
        else if ([NBFileKeyLength isEqualToString:aKey]) { // length
            NSString *length = aValue;
            self.contentLength = length.longLongValue;
        }
        else if ([NBFileKeyAclBody isEqualToString:aKey]) { // acl
            NBAcl *aclFromJson = [[NBAcl alloc] init];
            [aclFromJson setEntriesDictionary:aValue];
            self.acl = aclFromJson;
        }
        else if ([NBFileKeyCreated isEqualToString:aKey]) { // createdAt
            NSString *date = aValue;
            self.created = [NBUtilities dateWithString:date];
        }
        else if ([NBFileKeyUpdated isEqualToString:aKey]) { // updatedAt
            NSString *date = aValue;
            self.updated = [NBUtilities dateWithString:date];
        }

        else if ([NBFileKeyMetaEtag isEqualToString:aKey]) { // metaETag
            self.etag = aValue;
        }
        else if ([NBFileKeyFileEtag isEqualToString:aKey]) { // fileETag
            self.fileEtag = aValue;
        }
        else if ([NBFileKeyPublicUrl isEqualToString:aKey]) { // publicUrl
            self.publicUrl = aValue;
        }
        // chacheDisabled unsupport
    }
}

#pragma mark - private methods

/**
 *  ファイルの新規/上書きアップロードを行う
 *
 *  @param type          新規/上書きを指定
 *  @param url           ファイルパス
 *  @param resultBlock   実行結果を受け取るブロック
 *  @param progressBlock 転送進捗を受け取るブロック
 */
- (void)executeUploadingFileInBackgroundWithType:(NBFileUploadType)type url:(NSURL*)url resultBlock:(NBFilesBlock)resultBlock
    progressBlock:(NBFileProgressBlock)progressBlock {

    // callbackで使用するためにBlockを保存
    NBFilesBlock resultBlockCopy = [resultBlock copy];
    NBFileProgressBlock progressBlockCopy = [progressBlock copy];

    // Request
    NSMutableDictionary *requestParam = [NSMutableDictionary dictionary];
    NSError *requestError = nil;
    NBHTTPMethod method = (type == NBFileUploadCreate) ? NBHTTPMethodPOST : NBHTTPMethodPUT;
    NBUseSessionToken useSessionToken = NBUseSessionTokenOptional;

    // HTTP Header
    NSMutableDictionary *headerDict = [NSMutableDictionary dictionary];
    // ACL
    if (type == NBFileUploadCreate) {
        if (self.acl) {
            NSDictionary *aclDictionary = [self.acl entriesDictionary];
            headerDict[NBFileKeyAclHeader] = aclDictionary;
        }
    }
    // ContentType
    if (self.contentType) {
        headerDict[NBFileKeyContentTypeHeader] = self.contentType;
    } else {
        [[NSException exceptionWithName:NSInvalidArgumentException
          reason:@"Content-Type is nil."
          userInfo:nil] raise];
    }

    // Request URL
    NSMutableString *apiUrlString = [NSMutableString string];
    [apiUrlString appendFormat:@"%@/%@/%@", NBFileApiUrl, self.bucketName, [NBUtilities encodeURI:self.fileName]];

    // Request Parameter
    if(type == NBFileUploadUpdate) {
        if (self.etag) {
            requestParam[NBFileKeyMetaEtag] = self.etag;
        }
        if (self.fileEtag) {
            requestParam[NBFileKeyFileEtag] = self.fileEtag;
        }
    }
    // cacheDisabled unsupport

    NSURLRequest *request =
        [NBURLRequestFactory makeRequestForMethod:method
         url:apiUrlString
         useToken:useSessionToken
         header:headerDict
         param:requestParam error:&requestError];

    if (requestError) {
        dispatch_async(dispatch_get_main_queue(), ^{
            resultBlockCopy(nil, requestError);
        });
        return;
    }

    // execute
    NBRestExecutor *executor = [NBRestExecutor executorWithRequest:request name:@"executeUploadingFileInBackgroundWithType"];
    [executor executeUploadRequestInBackgroundWithURL:url block:^(NSData *data, NSError *error) {

         NSMutableDictionary *jsonDict = nil;
         NSMutableArray *resultArray = nil;

         if (error) {
             resultBlockCopy(resultArray, error);
             return;
         }

         jsonDict = [NSJSONSerialization JSONObjectWithData:data options:0 error:&error];

         if (jsonDict)  {
             // NBFile作る
             NBFile * aFile = [NBFile objectWithBucketName:self.bucketName];
             [aFile setPropertiesWithDictionary:jsonDict];

             // NBFileをArrayへ格納
             resultArray = [NSMutableArray array];
             [resultArray addObject:aFile];
         }

         resultBlockCopy(resultArray, error);

     } progressBlock:^(int64_t transferred, int64_t expected) {
         if (progressBlockCopy) progressBlockCopy(transferred,  expected);
     }];

}

/**
 *  ファイルの公開状態設定変更を行う
 *
 *  @param type  公開/非公開を指定
 *  @param block 実行結果を受け取るブロック
 */
- (void)executePublishingFileInBackgroundWithType:(NBFilePublishingType)type block:(NBFilesBlock)block {
    // callbackで使用するためにBlockを保存
    NBFilesBlock copyBlock = [block copy];

    // Requset
    NSError *requestError = nil;
    NBHTTPMethod method = (type == NBFilePublishingDisabled) ? NBHTTPMethodDELETE : NBHTTPMethodPUT;
    NBUseSessionToken useSessionToken = NBUseSessionTokenOptional;


    // URL
    NSMutableString *apiUrlString = [NSMutableString string];
    [apiUrlString appendFormat:@"%@/%@/%@/%@", NBFileApiUrl, self.bucketName, [NBUtilities encodeURI:self.fileName], NBFileURLPublish];

    // Request Parameters
    NSMutableDictionary *requestParam = [NSMutableDictionary dictionary];
    if (self.etag) {
        requestParam[NBFileKeyMetaEtag] = self.etag;
    }

    NSURLRequest *request =
        [NBURLRequestFactory makeRequestForMethod:method url:apiUrlString useToken:useSessionToken param:requestParam error:&
         requestError];

    if (requestError) {
        dispatch_async(dispatch_get_main_queue(), ^{
            copyBlock(nil,requestError);
        });
        return;
    }

    // execute
    NBRestExecutor *executor = [NBRestExecutor executorWithRequest:request name:@"executePublishingFileInBackgroundWithType"];
    [executor executeRequestInBackgroundWithBlock:^(NSData *data, NSError *error) {

         NSMutableDictionary *jsonDict = nil;
         NSMutableArray *resultArray = nil;

         if (error) {
             copyBlock(resultArray, error);
             return;
         }

         jsonDict = [NSJSONSerialization JSONObjectWithData:data options:0 error:&error];

         if (jsonDict)  {
             // NBFile作る
             NBFile * aFile = [NBFile objectWithBucketName:self.bucketName];
             [aFile setPropertiesWithDictionary:jsonDict];

             // NBFileをArrayへ格納
             resultArray = [NSMutableArray array];
             [resultArray addObject:aFile];
         }
         copyBlock(resultArray, error);

     }];

}

@end
