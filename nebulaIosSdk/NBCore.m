//
//  NBCore.m
//
//  COPYRIGHT (C) 2014 NEC CORPORATION
//


#import "Headers/NBCore.h"
#import "NBURLSession.h"
#import "Common.h"

@interface NBCore ()

@property (nonatomic) NSString *appId;
@property (nonatomic) NSString *appKey;
@property (nonatomic) NSString *tenantId;
@property (nonatomic) NSString *endPointUri;

@end

// like a class variables
static NBCore *sharedInstance = nil;

@implementation NBCore

static NSString *const NBEndPointUriCloud = @"";

#pragma mark - public methods

+ (void)setUpWithAppId:(NSString *)appId appKey:(NSString *)appKey tenantId:(NSString *)tenantId {
    NSAssert(appId != nil, @"appId is nil");
    NSAssert(appKey != nil, @"appKey is nil");
    NSAssert(tenantId != nil, @"tenantId is nil");

    [self sharedInstance].appId = appId;
    [self sharedInstance].appKey = appKey;
    [self sharedInstance].tenantId = tenantId;
}

+ (void)setEndPointUri:(NSString *)endPointUri {
    NSAssert(endPointUri != nil, @"endPointUri is nil");
    [self sharedInstance].endPointUri = endPointUri;
}

+ (NSString *)appId {
    return [self sharedInstance].appId;
}

+ (NSString *)appKey {
    return [self sharedInstance].appKey;
}

+ (NSString *)tenantId {
    return [self sharedInstance].tenantId;
}

+ (NSString *)endPointUri {
    NSString *result = [self sharedInstance].endPointUri;
    if (!result) {
        result = NBEndPointUriCloud;
    }
    return result;
}

+ (void)recreateSessionWithIdentifier:(NSString *)identifier completionHandler:(void (^)(void))completionHandler {
    [[NBURLSession sharedInstance] recreateSessionWithIdentifier:identifier completionHandler:completionHandler];
}

+ (id)allocWithZone:(NSZone *)zone {
    // 既にインスタンス化されている状態でallocがコールされたら
    // 生成済みのインスタンスを返すようにする
    DLog(@"allocWithZone: sharedInstance(before): %@", sharedInstance);
    static dispatch_once_t once;
    dispatch_once(&once, ^{
        sharedInstance = [super allocWithZone:zone];
    });
    DLog(@"allocWithZone: sharedInstance(after) : %@", sharedInstance);
    return sharedInstance;
}

- (id)copyWithZone:(NSZone *)zone {
    DLog(@"copyWithZone: self: %@", self);
    return self;
}

- (instancetype)init {
    if (self = [super init]) {
        self.appId = nil;
        self.appKey = nil;
        self.tenantId = nil;
        self.endPointUri = nil;
    }
    return self;
}


#pragma mark - private methods

/**
 *  Singletonインスタンスを取得する。
 *
 *  @return Singletonインスタンス
 */
+ (NBCore *)sharedInstance {
    static dispatch_once_t once;
    dispatch_once(&once, ^{
        // allocが実行されるとallocWithZoneが実行され、そちらで代入されるので、
        // ここではsharedInstanceに代入しない
        (void)[[self alloc] init];
    });

    DLog(@"sharedInstance: %@", sharedInstance);
    return sharedInstance;
}

@end
