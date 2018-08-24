//
//  NBPush.m
//
//  COPYRIGHT (C) 2014 NEC CORPORATION
//

#import "Headers/NBPush.h"
#import "Headers/NBAPNSFields.h"
#import "Headers/NBGCMFields.h"
#import "NBURLRequestFactory.h"
#import "NBRestExecutor.h"
#import "Common.h"

@implementation NBPush

/**
 *  定数
 */
// key
static NSString *const NBKeyQuery = @"query";
static NSString *const NBKeyMessage = @"message";
static NSString *const NBKeyAllowedReceivers = @"allowedReceivers";

// URL
static NSString *const NBURLPushNotifications = @"/push/notifications";

#pragma mark -
#pragma mark public methods

- (void)sendPushInBackgroundWithBlock:(NBPushBlock)block {
    // blockを保存する(ヒープ領域に移動する)
    NBPushBlock copyBlock = [block copy];
    NSError *error = nil;
    NSNull *nul = [NSNull null];

    // リクエストボディ部作成
    // nilオブジェクト、NSNull値は含めない
    NSMutableDictionary *bodyDict = [NSMutableDictionary dictionary];

    if (self.query && ![self.query isEqual:nul]) {
        bodyDict[NBKeyQuery] = self.query;
    }

    if (self.message && ![self.message isEqual:nul]) {
        bodyDict[NBKeyMessage] = self.message;
    }

    if (self.allowedReceivers && ![self.allowedReceivers isEqual:nul]) {
        bodyDict[NBKeyAllowedReceivers] = self.allowedReceivers;
    }

    if (self.apnsFields && ![self.apnsFields isEqual:nul]) {
        NSDictionary *apnsFields = [self.apnsFields dictionaryValue];
        [bodyDict addEntriesFromDictionary:apnsFields];
    }

    if (self.gcmFields && ![self.gcmFields isEqual:nul]) {
        NSDictionary *gcmFields = [self.gcmFields dictionaryValue];
        [bodyDict addEntriesFromDictionary:gcmFields];
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
    NSURLRequest *request = [NBURLRequestFactory makeRequestForMethod:NBHTTPMethodPOST
                             url:NBURLPushNotifications
                             useToken:NBUseSessionTokenNotUse
                             body:bodyData
                             error:&error];
    if (error) {
        dispatch_async(dispatch_get_main_queue(), ^{
            copyBlock(nil, error);
        });
        return;
    }

    // リクエスト送信
    NBRestExecutor *executor = [NBRestExecutor executorWithRequest:request name:@"sendPushInBackgroundWithBlock"];
    [executor executeRequestInBackgroundWithBlock:^(NSData *data, NSError *error) {
         id jsonObject = nil;

         if (!error) {
             // NSData -> JSON Object
             jsonObject = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableContainers error:&error];
         }

         copyBlock(jsonObject, error);
     }];
}

- (instancetype)init {
    self = [super init];

    if (self) {
        self.query = nil;
        self.message = nil;
        self.allowedReceivers = nil;
        self.apnsFields = nil;
        self.gcmFields = nil;
    }

    return self;
}

@end
