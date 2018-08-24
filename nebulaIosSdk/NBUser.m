//
//  NBUser.m
//
//  COPYRIGHT (C) 2014 NEC CORPORATION
//


#import "Headers/NBUser.h"

#import "NBURLRequestFactory.h"
#import "NBRestExecutor.h"
#import "NBSessionInfo.h"
#import "NBUtilities.h"
#import "Common.h"

@interface NBUser ()

@property (nonatomic) NSString *userId;
@property (nonatomic) NSDate *created;
@property (nonatomic) NSDate *updated;

@end

@implementation NBUser

// key
static NSString *const NBKeyUserId = @"_id";
static NSString *const NBKeyUsername = @"username";
static NSString *const NBKeyEmail = @"email";
static NSString *const NBKeyCreated = @"createdAt";
static NSString *const NBKeyUpdated = @"updatedAt";
static NSString *const NBKeyPassword = @"password";
static NSString *const NBKeySessionToken = @"sessionToken";
static NSString *const NBKeySessionTokenExpiration = @"expire";
static NSString *const NBKeyResults = @"results";

// URL
static NSString *const NBURLUsers = @"/users";
static NSString *const NBURLLogin = @"/login";
static NSString *const NBURLPasswordReset = @"/request_password_reset";
static NSString *const NBURLCurrent = @"/current";

#pragma mark -
#pragma mark public methods

- (void)signUpInBackgroundWithPassword:(NSString *)password block:(NBUserBlock)block {
    // blockを保存する(ヒープ領域に移動する)
    NBUserBlock copyBlock = [block copy];

    // create request body
    NSMutableDictionary *body = [[NSMutableDictionary alloc] init];
    // nilとなっているパラメータは無視する
    if (self.email) {
        body[NBKeyEmail] = self.email;
    }
    if (password) {
        body[NBKeyPassword] = password;
    }
    if (self.username) {
        body[NBKeyUsername] = self.username;
    }
    NSError *error = nil;
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:body options:NSJSONWritingPrettyPrinted error:&error];
    DLog(@"%@", [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding]);
    if (error) {
        dispatch_async(dispatch_get_main_queue(), ^{
                           copyBlock(nil, error);
                       });
        return;
    }

    NSURLRequest *request = [NBURLRequestFactory makeRequestForMethod:NBHTTPMethodPOST
                             url:NBURLUsers
                             useToken:NBUseSessionTokenNotUse
                             body:jsonData
                             error:&error];
    if (error) {
        dispatch_async(dispatch_get_main_queue(), ^{
                           copyBlock(nil, error);
                       });
        return;
    }

    // request to server
    NBRestExecutor *executor = [NBRestExecutor executorWithRequest:request name:@"signUpInBackgroundWithPassword"];
    [executor executeRequestInBackgroundWithBlock:^(NSData *data, NSError *error) {
         DLog(@"ThreadId: %@ : [%@]callback OK", [NSThread currentThread], [self class]);

         id body = nil;
         if (!error) {
             body = [NSJSONSerialization JSONObjectWithData:data options:0 error:&error];
         }
         NBUser *user = nil;
         if (!error) {
             user = [NBUser userFromJson:body];
         }
         copyBlock(user, error);
     }];
}

+ (void)logInInBackgroundWithUsername:(NSString *)username email:(NSString *)email password:(NSString *)password block:(NBUserBlock)block {
    // blockを保存する(ヒープ領域に移動する)
    NBUserBlock copyBlock = [block copy];

    // create request body
    NSMutableDictionary *body = [[NSMutableDictionary alloc] init];
    if (password) {
        body[NBKeyPassword] = password;
    }
    if (email) {
        body[NBKeyEmail] = email;
    }
    if (username) {
        body[NBKeyUsername] = username;
    }

    NSError *error = nil;
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:body options:NSJSONWritingPrettyPrinted error:&error];
    DLog(@"%@", [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding]);
    if (error) {
        dispatch_async(dispatch_get_main_queue(), ^{
                           copyBlock(nil, error);
                       });
        return;
    }

    NSURLRequest *request = [NBURLRequestFactory makeRequestForMethod:NBHTTPMethodPOST
                             url:NBURLLogin
                             useToken:NBUseSessionTokenNotUse
                             body:jsonData
                             error:&error];
    if (error) {
        dispatch_async(dispatch_get_main_queue(), ^{
                           copyBlock(nil, error);
                       });
        return;
    }

    // request to server
    NBRestExecutor *executor = [NBRestExecutor executorWithRequest:request name:@"logInInBackgroundWithUsername"];
    [executor executeRequestInBackgroundWithBlock:^(NSData *data, NSError *error) {
         DLog(@"ThreadId: %@ : [%@]callback OK", [NSThread currentThread], [self class]);

         id body = nil;
         if (!error) {
             body = [NSJSONSerialization JSONObjectWithData:data options:0 error:&error];
         }
         NBUser *user = nil;
         if (!error) {
             user = [NBUser userFromJson:body];
             // save user information and sessionToken
             [NBSessionInfo setSessionUser:[user dictionaryWithValuesForKeys:[user userKeys]]];
             [NBSessionInfo setSessionToken:body[NBKeySessionToken] expiration:body[NBKeySessionTokenExpiration]];
             user = [NBUser currentUser];
         }
         copyBlock(user, error);
     }];
}

+ (void)logOutInBackgroundWithBlock:(NBUserBlock)block {
    // blockを保存する(ヒープ領域に移動する)
    NBUserBlock copyBlock = [block copy];

    NSError *error = nil;
    NSURLRequest *request = [NBURLRequestFactory makeRequestForMethod:NBHTTPMethodDELETE
                             url:NBURLLogin
                             useToken:NBUseSessionTokenMust
                             error:&error];
    if (error) {
        dispatch_async(dispatch_get_main_queue(), ^{
                           copyBlock(nil, error);
                       });
        return;
    }

    // request to server
    NBRestExecutor *executor = [NBRestExecutor executorWithRequest:request name:@"logOutInBackgroundWithBlock"];
    [executor executeRequestInBackgroundWithBlock:^(NSData *data, NSError *error) {
         DLog(@"ThreadId: %@ : [%@]callback OK", [NSThread currentThread], [self class]);

         id body = nil;
         if (!error) {
             body = [NSJSONSerialization JSONObjectWithData:data options:0 error:&error];
         }
         NBUser *user = nil;
         if (!error) {
             user = [NBUser userFromJson:body];
             // clear user information and sessionToken
             [NBSessionInfo clearSessionInfo];
         }
         copyBlock(user, error);
     }];
}

+ (void)resetPasswordInBackgroundWithUsername:(NSString *)username email:(NSString *)email block:(NBResultBlock)block {
    // blockを保存する(ヒープ領域に移動する)
    NBResultBlock copyBlock = [block copy];

    // create request body
    NSMutableDictionary *body = [[NSMutableDictionary alloc] init];
    if (username) {
        body[NBKeyUsername] = username;
    }
    if (email) {
        body[NBKeyEmail] = email;
    }

    NSError *error = nil;
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:body options:NSJSONWritingPrettyPrinted error:&error];
    DLog(@"%@", [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding]);
    if (error) {
        dispatch_async(dispatch_get_main_queue(), ^{
                           copyBlock(error);
                       });
        return;
    }

    NSURLRequest *request = [NBURLRequestFactory makeRequestForMethod:NBHTTPMethodPOST
                             url:NBURLPasswordReset
                             useToken:NBUseSessionTokenNotUse
                             body:jsonData
                             error:&error];
    if (error) {
        dispatch_async(dispatch_get_main_queue(), ^{
                           copyBlock(error);
                       });
        return;
    }

    // request to server
    NBRestExecutor *executor = [NBRestExecutor executorWithRequest:request name:@"resetPasswordInBackgroundWithUsername"];
    [executor executeRequestInBackgroundWithBlock:^(NSData *data, NSError *error) {
         DLog(@"ThreadId: %@ : [%@]callback OK", [NSThread currentThread], [self class]);

         copyBlock(error);
     }];
}

- (void)saveInBackgroundWithPassword:(NSString *)password block:(NBUserBlock)block {
    // blockを保存する(ヒープ領域に移動する)
    NBUserBlock copyBlock = [block copy];

    // create request body
    NSMutableDictionary *body = [[NSMutableDictionary alloc] init];
    if (self.username) {
        body[NBKeyUsername] = self.username;
    }
    if (self.email) {
        body[NBKeyEmail] = self.email;
    }
    if (password) {
        body[NBKeyPassword] = password;
    }
    NSError *error = nil;
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:body options:NSJSONWritingPrettyPrinted error:&error];
    DLog(@"%@", [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding]);
    if (error) {
        dispatch_async(dispatch_get_main_queue(), ^{
                           copyBlock(nil, error);
                       });
        return;
    }

    NSURLRequest *request = [NBURLRequestFactory makeRequestForMethod:NBHTTPMethodPUT
                             url:[NBURLUsers stringByAppendingFormat:@"/%@", self.userId]
                             useToken:NBUseSessionTokenMust
                             body:jsonData
                             error:&error];
    if (error) {
        dispatch_async(dispatch_get_main_queue(), ^{
                           copyBlock(nil, error);
                       });
        return;
    }

    // request to server
    NBRestExecutor *executor = [NBRestExecutor executorWithRequest:request name:@"saveInBackgroundWithPassword"];
    [executor executeRequestInBackgroundWithBlock:^(NSData *data, NSError *error) {
         DLog(@"ThreadId: %@ : [%@]callback OK", [NSThread currentThread], [self class]);

         id body = nil;
         if (!error) {
             body = [NSJSONSerialization JSONObjectWithData:data options:0 error:&error];
         }
         NBUser *user = nil;
         if (!error) {
             user = [NBUser userFromJson:body];
             // ログイン中ユーザが変更された場合はキャッシュを更新する
             NBUser *currentUser = [NBUser currentUser];
             if (currentUser && currentUser.userId && [currentUser.userId isEqualToString:user.userId]) {
                 // save user information
                 [NBSessionInfo setSessionUser:[user dictionaryWithValuesForKeys:[user userKeys]]];
                 user = [NBUser currentUser];
             }
         }
         copyBlock(user, error);
     }];
}

- (void)deleteInBackgroundWithBlock:(NBResultBlock)block {
    // blockを保存する(ヒープ領域に移動する)
    NBResultBlock copyBlock = [block copy];

    NSError *error = nil;
    NSURLRequest *request = [NBURLRequestFactory makeRequestForMethod:NBHTTPMethodDELETE
                             url:[NBURLUsers stringByAppendingFormat:@"/%@", self.userId]
                             useToken:NBUseSessionTokenMust
                             error:&error];
    if (error) {
        dispatch_async(dispatch_get_main_queue(), ^{
                           copyBlock(error);
                       });
        return;
    }

    // request to server
    NBRestExecutor *executor = [NBRestExecutor executorWithRequest:request name:@"deleteInBackgroundWithBlock"];
    [executor executeRequestInBackgroundWithBlock:^(NSData *data, NSError *error) {
         DLog(@"ThreadId: %@ : [%@]callback OK", [NSThread currentThread], [self class]);

         if (!error) {
             // ログイン中ユーザが削除された場合はトークンやキャッシュを削除する
             NBUser *currentUser = [NBUser currentUser];
             if (currentUser && currentUser.userId && [currentUser.userId isEqualToString:self.userId]) {
                 // clear user information and sessionToken
                 [NBSessionInfo clearSessionInfo];
             }
         }
         copyBlock(error);
     }];
}

+ (void)queryUserInBackgroundWithUsername:(NSString *)username email:(NSString *)email block:(NBUsersBlock)block {
    // blockを保存する(ヒープ領域に移動する)
    NBUsersBlock copyBlock = [block copy];

    // create request body
    NSMutableDictionary *params = [[NSMutableDictionary alloc] init];
    if (username) {
        params[NBKeyUsername] = username;
    }
    if (email) {
        params[NBKeyEmail] = email;
    }

    NSError *error = nil;
    NSURLRequest *request = [NBURLRequestFactory makeRequestForMethod:NBHTTPMethodGET
                             url:NBURLUsers
                             useToken:NBUseSessionTokenOptional
                             param:params
                             error:&error];
    if (error) {
        dispatch_async(dispatch_get_main_queue(), ^{
                           copyBlock(nil, error);
                       });
        return;
    }

    // request to server
    NBRestExecutor *executor = [NBRestExecutor executorWithRequest:request name:@"queryUserInBackgroundWithUsername"];
    [executor executeRequestInBackgroundWithBlock:^(NSData *data, NSError *error) {
         DLog(@"ThreadId: %@ : [%@]callback OK", [NSThread currentThread], [self class]);

         id body = nil;
         if (!error) {
             body = [NSJSONSerialization JSONObjectWithData:data options:0 error:&error];
         }
         NSArray *users = nil;
         if (!error) {
             users = [NBUser usersFromJson:body[NBKeyResults]];
         }
         copyBlock(users, error);
     }];
}

+ (void)getUserInBackgroundWithUserId:(NSString *)userId block:(NBUserBlock)block {
    // blockを保存する(ヒープ領域に移動する)
    NBUserBlock copyBlock = [block copy];

    NSError *error = nil;
    NSURLRequest *request = [NBURLRequestFactory makeRequestForMethod:NBHTTPMethodGET
                             url:[NBURLUsers stringByAppendingFormat:@"/%@", userId]
                             useToken:NBUseSessionTokenOptional
                             error:&error];
    if (error) {
        dispatch_async(dispatch_get_main_queue(), ^{
                           copyBlock(nil, error);
                       });
        return;
    }

    // request to server
    NBRestExecutor *executor = [NBRestExecutor executorWithRequest:request name:@"getUserInBackgroundWithUserId"];
    [executor executeRequestInBackgroundWithBlock:^(NSData *data, NSError *error) {
         DLog(@"ThreadId: %@ : [%@]callback OK", [NSThread currentThread], [self class]);

         id body = nil;
         if (!error) {
             body = [NSJSONSerialization JSONObjectWithData:data options:0 error:&error];
         }
         NBUser *user = nil;
         if (!error) {
             user = [NBUser userFromJson:body];
         }
         copyBlock(user, error);
     }];
}

+ (void)refreshCurrentUserInBackgroundWithBlock:(NBUserBlock)block {
    // blockを保存する(ヒープ領域に移動する)
    NBUserBlock copyBlock = [block copy];

    NSError *error = nil;
    NSURLRequest *request = [NBURLRequestFactory makeRequestForMethod:NBHTTPMethodGET
                             url:[NBURLUsers stringByAppendingString:NBURLCurrent]
                             useToken:NBUseSessionTokenMust
                             error:&error];
    if (error) {
        dispatch_async(dispatch_get_main_queue(), ^{
                           copyBlock(nil, error);
                       });
        return;
    }

    // request to server
    NBRestExecutor *executor = [NBRestExecutor executorWithRequest:request name:@"refreshCurrentUserInBackgroundWithBlock"];
    [executor executeRequestInBackgroundWithBlock:^(NSData *data, NSError *error) {
         DLog(@"ThreadId: %@ : [%@]callback OK", [NSThread currentThread], [self class]);

         id body = nil;
         if (!error) {
             body = [NSJSONSerialization JSONObjectWithData:data options:0 error:&error];
         }
         NBUser *user = nil;
         if (!error) {
             user = [NBUser userFromJson:body];
             // save user information
             [NBSessionInfo setSessionUser:[user dictionaryWithValuesForKeys:[user userKeys]]];
             user = [NBUser currentUser];
         }
         copyBlock(user, error);
     }];
}

+ (NBUser *)currentUser {
    NBUser *user = [[NBUser alloc] init];
    [user setValuesForKeysWithDictionary:[NBSessionInfo sessionUser]];
    return user;
}

+ (BOOL)loggedIn {
    if ([NBSessionInfo sessionToken] == nil) {
        return NO;
    }

    long long expire = [[NBSessionInfo expiration] longLongValue];
    NSTimeInterval now = [[NSDate new] timeIntervalSince1970];
    if (expire < now) {
        return NO;
    }

    return YES;
}

+ (NSString *)sessionToken {
    return [NBSessionInfo sessionToken];
}

+ (long long)sessionTokenExpiration {
    return [[NBSessionInfo expiration] longLongValue];
}

- (instancetype)init {
    if (self = [super init]) {
        self.userId = nil;
        self.username = nil;
        self.email = nil;
        self.created = nil;
        self.updated = nil;
    }
    return self;
}

#pragma mark -
#pragma mark private methods

/**
 *  ユーザ情報のJSONからユーザインスタンスを生成する。
 *
 *  @param json ユーザ情報を示すJSON
 *
 *  @return ユーザ情報が格納されたユーザインスタンス
 */
+ (NBUser *)userFromJson:(NSDictionary *)json {
    NBUser *user = [[NBUser alloc] init];
    user.userId = json[NBKeyUserId];
    user.username = json[NBKeyUsername];
    user.email = json[NBKeyEmail];
    user.created = [NBUtilities dateWithString:json[NBKeyCreated]];
    user.updated = [NBUtilities dateWithString:json[NBKeyUpdated]];
    return user;
}

/**
 *  ユーザ情報リストのJSONからユーザインスタンスのリストを生成する。
 *
 *  @param json ユーザ情報のリストを示すJSON
 *
 *  @return ユーザ情報が格納されたユーザインスタンスのリスト
 */
+ (NSArray *)usersFromJson:(NSArray *)json {
    NSMutableArray *users = [NSMutableArray array];
    [json enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
         NBUser *user = [NBUser userFromJson:obj];
         [users addObject:user];
     }];
    return users;
}

/**
 *  要素キー取得
 *
 *  独自クラスの要素として取り扱うプロパティ名の一覧をNSArray型で返却する。
 *
 *  @return 要素キーを含めた配列
 */
- (NSArray *)userKeys {
    return @[@"userId", @"username", @"email", @"created", @"updated"];
}

- (void)setValue:(id)value forUndefinedKey:(NSString *)key {
    DLog(@"Error: setting unknown key: %@ with data: %@", key, value);
}

@end
