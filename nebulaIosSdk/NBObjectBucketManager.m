//
//  NBObjectBucketManager.m
//
//  COPYRIGHT (C) 2014 NEC CORPORATION
//

#import "Headers/NBObjectBucketManager.h"
#import "Headers/NBObjectBucket.h"

@implementation NBObjectBucketManager

static NBObjectBucketManager *singleInstance = nil;

#pragma mark -
#pragma mark public methods

+ (NBObjectBucketManager *)sharedInstance {

    static dispatch_once_t once;
    dispatch_once(&once, ^{
        // allocが実行されるとallocWithZoneが実行され、そちらでsingleInstanceに代入されるので、
        // ここではsharedInstanceに代入しない
        (void)[[self alloc] init];
    });
    return singleInstance;
}

- (NBObjectBucket *)bucketWithName:(NSString *)bucketName {
    return [[NBObjectBucket alloc] initWithBucketName:bucketName];
}

+ (id)allocWithZone:(NSZone *)zone {
    // 既にインスタンス化されている状態でallocがコールされたら
    // 生成済みのインスタンスを返すようにする
    static dispatch_once_t once;
    dispatch_once(&once, ^{
        singleInstance = [super allocWithZone:zone];
    });
    return singleInstance;
}

- (id)copyWithZone:(NSZone *)zone {
    return [[self class] sharedInstance];
}

@end