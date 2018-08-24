//
//  NBGroup.m
//
//  COPYRIGHT (C) 2014 NEC CORPORATION
//


#import "Headers/NBGroup.h"
#import "Headers/NBAcl.h"

#import "NBURLRequestFactory.h"
#import "NBRestExecutor.h"
#import "NBUtilities.h"
#import "Common.h"

@interface NBGroup ()

@property (nonatomic) NSString *groupId;
@property (nonatomic) NSString *name;
@property (nonatomic) NSDate *created;
@property (nonatomic) NSDate *updated;

@end


@implementation NBGroup

// key
static NSString *const NBKeyId = @"_id";
static NSString *const NBKeyName = @"name";
static NSString *const NBKeyUsers = @"users";
static NSString *const NBKeyGroups = @"groups";
static NSString *const NBKeyAcl = @"ACL";
static NSString *const NBKeyCreated = @"createdAt";
static NSString *const NBKeyUpdated = @"updatedAt";
static NSString *const NBKeyResults = @"results";

// URL
static NSString *const NBURLGroups = @"/groups";


#pragma mark - public methods

- (instancetype)initWithName:(NSString *)name {
    if (self = [super init]) {
        // Group名は書き換え不可
        self.name = [name copy];
        self.users = nil;
        self.groups = nil;
        self.groupId = nil;
        self.created = nil;
        self.updated = nil;
        self.acl = nil;
    }
    return self;
}

/**
 *  NBGroupをGroup名無指定で初期化を行う
 *
 *  @return Group名にnilを指定したNBObjectのインスタンス
 */
- (instancetype)init {
    return [self initWithName:nil];
}

+ (instancetype)groupWithName:(NSString *)name {
    id instance = [[[self class] alloc] initWithName:name];
    return instance;
}

- (void)saveInBackgroundWithBlock:(NBGroupsBlock)block {
    // blockを保存する(ヒープ領域に移動する)
    NBGroupsBlock copyBlock = [block copy];

    // create request body
    NSMutableDictionary *body = [NSMutableDictionary dictionary];
    if (self.users) {
        body[NBKeyUsers] = self.users;
    }
    if (self.groups) {
        body[NBKeyGroups] = self.groups;
    }
    if (self.acl) {
        NSDictionary *aclDictionary = [self.acl entriesDictionary];
        body[NBKeyAcl] = aclDictionary;
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
                             url:[NBURLGroups stringByAppendingFormat:@"/%@", self.name]
                             useToken:NBUseSessionTokenOptional
                             body:jsonData
                             error:&error];
    if (error) {
        dispatch_async(dispatch_get_main_queue(), ^{
            copyBlock(nil, error);
        });
        return;
    }

    // request to server
    NBRestExecutor *executor = [NBRestExecutor executorWithRequest:request name:@"saveInBackgroundWithBlock"];
    [executor executeRequestInBackgroundWithBlock:^(NSData *data, NSError *error) {
         DLog(@"ThreadId: %@ : [%@]callback OK", [NSThread currentThread], [self class]);

         id jsonObject = nil;
         if (!error) {
             jsonObject = [NSJSONSerialization JSONObjectWithData:data options:0 error:&error];
         }
         NSMutableArray *groups = nil;
         if (!error) {
             NBGroup *group = [[self class] groupFromJson:jsonObject];

             // callback用のデータを格納
             groups = [NSMutableArray array];
             [groups addObject:group];
         }
         copyBlock(groups, error);
     }];
}

- (void)deleteInBackgroundWithBlock:(NBResultBlock)block {
    // blockを保存する(ヒープ領域に移動する)
    NBResultBlock copyBlock = [block copy];

    NSError *error = nil;
    NSURLRequest *request = [NBURLRequestFactory makeRequestForMethod:NBHTTPMethodDELETE
                             url:[NBURLGroups stringByAppendingFormat:@"/%@", self.name]
                             useToken:NBUseSessionTokenOptional
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

         copyBlock(error);
     }];
}

+ (void)queryGroupInBackgroundWithBlock:(NBGroupsBlock)block {
    // blockを保存する(ヒープ領域に移動する)
    NBGroupsBlock copyBlock = [block copy];

    NSError *error = nil;
    NSURLRequest *request = [NBURLRequestFactory makeRequestForMethod:NBHTTPMethodGET
                             url:NBURLGroups
                             useToken:NBUseSessionTokenOptional
                             error:&error];
    if (error) {
        dispatch_async(dispatch_get_main_queue(), ^{
            copyBlock(nil, error);
        });
        return;
    }

    // request to server
    NBRestExecutor *executor = [NBRestExecutor executorWithRequest:request name:@"queryGroupInBackgroundWithBlock"];
    [executor executeRequestInBackgroundWithBlock:^(NSData *data, NSError *error) {
         DLog(@"ThreadId: %@ : [%@]callback OK", [NSThread currentThread], [self class]);

         id jsonObject = nil;
         if (!error) {
             jsonObject = [NSJSONSerialization JSONObjectWithData:data options:0 error:&error];
         }
         NSMutableArray *groups = nil;
         if (!error) {
             groups = [NSMutableArray array];
             for (NSDictionary * aGroupDict in jsonObject[NBKeyResults]) {
                 NBGroup *group = [[self class] groupFromJson:aGroupDict];
                 [groups addObject:group];
             }
         }
         copyBlock(groups, error);
     }];
}

+ (void)getGroupInBackgroundWithName:(NSString *)name block:(NBGroupsBlock)block {
    // blockを保存する(ヒープ領域に移動する)
    NBGroupsBlock copyBlock = [block copy];

    NSError *error = nil;
    NSURLRequest *request = [NBURLRequestFactory makeRequestForMethod:NBHTTPMethodGET
                             url:[NBURLGroups stringByAppendingFormat:@"/%@", name]
                             useToken:NBUseSessionTokenOptional
                             error:&error];
    if (error) {
        dispatch_async(dispatch_get_main_queue(), ^{
            copyBlock(nil, error);
        });
        return;
    }

    // request to server
    NBRestExecutor *executor = [NBRestExecutor executorWithRequest:request name:@"getGroupInBackgroundWithName"];
    [executor executeRequestInBackgroundWithBlock:^(NSData *data, NSError *error) {
         DLog(@"ThreadId: %@ : [%@]callback OK", [NSThread currentThread], [self class]);

         id jsonObject = nil;
         if (!error) {
             jsonObject = [NSJSONSerialization JSONObjectWithData:data options:0 error:&error];
         }
         NSMutableArray *groups = nil;
         if (!error) {
             NBGroup *group = [[self class] groupFromJson:jsonObject];

             // callback用のデータを格納
             groups = [NSMutableArray array];
             [groups addObject:group];
         }
         copyBlock(groups, error);
     }];
}


#pragma mark - private methods

/**
 *  グループ情報のJSONからグループインスタンスを生成する。
 *
 *  @param json グループ情報を示すJSON
 *
 *  @return グループ情報が格納されたグループインスタンス
 */
+ (NBGroup *)groupFromJson:(NSDictionary *)json {
    NBGroup *group = [[self class] new];
    for (NSString *aKey in json) {
        id aValue = json[aKey];

        if ([NBKeyId isEqualToString:aKey]) {
            group.groupId = aValue;
        }
        else if ([NBKeyName isEqualToString:aKey]) {
            group.name = aValue;
        }
        else if ([NBKeyCreated isEqualToString:aKey]) {
            NSString *date = aValue;
            group.created = [NBUtilities dateWithString:date];
        }
        else if ([NBKeyUpdated isEqualToString:aKey]) {
            NSString *date = aValue;
            group.updated = [NBUtilities dateWithString:date];
        }
        else if ([NBKeyAcl isEqualToString:aKey]) {
            NBAcl *acl = [NBAcl new];
            [acl setEntriesDictionary:aValue];
            group.acl = acl;
        }
        else if ([NBKeyUsers isEqualToString:aKey]) {
            group.users = [aValue mutableCopy];
        }
        else if ([NBKeyGroups isEqualToString:aKey]) {
            group.groups = [aValue mutableCopy];
        }
    }
    return group;
}

@end
