//
//  NBFileBucketManager.m
//
//  COPYRIGHT (C) 2014 NEC CORPORATION
//

#import "Headers/NBFileBucketManager.h"

@implementation NBFileBucketManager

static id singleInstance = nil;

#pragma mark -
#pragma mark public methods

+ (instancetype)sharedInstance {

    static dispatch_once_t once;
    dispatch_once(&once, ^{
        // allocが実行されるとallocWithZoneが実行され、そちらでsingleInstanceに代入されるので、
        // ここではsharedInstanceに代入しない
        (void)[[self alloc] init];
    });
    return singleInstance;
}

- (NBFileBucket *)bucketWithBucketName:(NSString *)bucketName {
    return [[NBFileBucket alloc] initWithName:bucketName];
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
    return self;
}

@end
