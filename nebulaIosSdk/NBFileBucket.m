//
//  NBFileBucket.m
//
//  COPYRIGHT (C) 2014 NEC CORPORATION
//

#import "Headers/NBFileBucket.h"
#import "Headers/NBFile.h"

#import "NBUtilities.h"
#import "NBRestExecutor.h"
#import "NBURLRequestFactory.h"
#import "NBErrorFactory.h"

@interface NBFileBucket ()
@property (nonatomic) NSString *bucketName;

@end

@implementation NBFileBucket

static NSString *const NBFileKeyURLMeta = @"meta";
static NSString *const NBFileKeyPublished = @"published";
static NSString *const NBFileKeyDeleteMark = @"deleteMark";

@synthesize bucketName;

// 親クラスの指定イニシャライザを override
- (instancetype)init {
    return [self initWithName:@""];
}

// 指定イニシャライザ
- (instancetype)initWithName:(NSString *)name {
    if (self = [super init]) {
        self.bucketName = name;
    }
    return self;
}

- (NBFile *)createObject {
    NBFile *object = [[NBFile alloc] initWithBucketName:self.bucketName];
    return object;
}

- (void)queryFileInBackgroundWithCondition:(NBFileCondition)condition block:(NBFilesBlock)block {

    // callbackで使用するためにBlockを保存
    NBFilesBlock copyBlock = [block copy];

    // Request
    NSError *requestError = nil;
    NBHTTPMethod method = NBHTTPMethodGET;
    NBUseSessionToken useSessionToken = NBUseSessionTokenOptional;
    NSMutableDictionary *requestParam = [NSMutableDictionary dictionary];

    // URL
    NSMutableString *apiUrlString = [NSMutableString string];
    [apiUrlString appendFormat:@"%@/%@", NBFileApiUrl, self.bucketName];

    // Request Parameters
    if (condition == NBFileConditionPublished) { //published
        requestParam[NBFileKeyPublished] = @"1";
    }

    // deleteMark unsuport
    requestParam[NBFileKeyDeleteMark] = @"1";

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
    NBRestExecutor *executor = [NBRestExecutor executorWithRequest:request name:@"queryFileInBackgroundWithCondition"];

    [executor executeRequestInBackgroundWithBlock:^(NSData *data, NSError *error) {

         NSMutableDictionary *jsonDict = nil;
         NSMutableArray *resultArray = nil;

         if (error) {
             copyBlock(resultArray, error);
             return;
         }

         jsonDict = [NSJSONSerialization JSONObjectWithData:data options:0 error:&error];

         if (jsonDict) {
             resultArray = [NSMutableArray array];

             for(NSDictionary * aDict in jsonDict[@"results"]) {
                 // NBFile new
                 NBFile * aFile = [NBFile objectWithBucketName:self.bucketName];

                 // set ObjectData
                 [aFile setPropertiesWithDictionary:aDict];

                 // add file
                 [resultArray addObject:aFile];
             }
         }

         copyBlock(resultArray, error);
     }];



}

- (void)getFileInBackgroundWithFilename:(NSString *)name block:(NBFilesBlock)block {
    // callbackで使用するためにBlockを保存
    NBFilesBlock copyBlock = [block copy];

    // Request
    NSError *requestError = nil;
    NBHTTPMethod method = NBHTTPMethodGET;
    NBUseSessionToken useSessionToken = NBUseSessionTokenOptional;
    NSMutableDictionary *requestParam = [NSMutableDictionary dictionary];

    // URL
    NSMutableString *apiUrlString = [NSMutableString string];
    [apiUrlString appendFormat:@"%@/%@/%@/%@", NBFileApiUrl, self.bucketName, [NBUtilities encodeURI:name], NBFileKeyURLMeta];

    // Request Parameters
    // deleteMark unsupport
    requestParam[NBFileKeyDeleteMark] = @"1";

    NSURLRequest *request =
        [NBURLRequestFactory makeRequestForMethod:method url:apiUrlString useToken:useSessionToken param:requestParam error:&
         requestError];
    if (requestError) {
        dispatch_async(dispatch_get_main_queue(), ^{
            copyBlock(nil,requestError);
        });
        return;
    }

    NBRestExecutor *executor = [NBRestExecutor executorWithRequest:request name:@"getFileInBackgroundWithFilename"];
    [executor executeRequestInBackgroundWithBlock:^(NSData *data, NSError *error) {

         NSMutableDictionary *jsonDict = nil;
         NSMutableArray *resultArray = nil;

         if (error) {
             copyBlock(resultArray, error);
             return;
         }

         jsonDict = [NSJSONSerialization JSONObjectWithData:data options:0 error:&error];

         if (jsonDict) {
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
