//
//  NBAcl.m
//
//  COPYRIGHT (C) 2014 NEC CORPORATION
//

#import "Headers/NBAcl.h"

@interface NBAclBase ()

- (NSMutableArray *)targetArray:(NBAclPermission)permission;

@end

@implementation NBAcl

#pragma mark -
#pragma mark public methods


- (instancetype)init {
    self = [super init];
    if (self != nil) {
        self.admin = [[NSMutableArray alloc] init];
        self.owner = [[NSString alloc] init];
    }
    return self;
}

#pragma mark -
#pragma mark private methods

/**
 *  要素キー取得
 *
 *  独自クラスの要素として取り扱うプロパティ名の一覧をNSArray型で返却する。
 *
 *  @return 要素キーを含めた配列
 */
- (NSArray *)aclKeys {
    return @[@"r", @"w", @"c", @"u", @"d", @"admin", @"owner"];
}

/**
 *  権限リスト取得
 *
 *  指定権限に対応する許可リストを返却する。
 *
 *  @param permission 権限
 *
 *  @return 許可リスト
 */
- (NSMutableArray *)targetArray:(NBAclPermission)permission {
    NSMutableArray *target;

    switch (permission) {
        case NBAclAdmin:
            target = self.admin;
            break;

        default:
            target = [super targetArray:permission];
            break;
    }

    return target;
}

- (void)setValue:(id)value forKey:(NSString *)key {

    if ([key isEqual:@"admin"]) {
        self.admin = [NSMutableArray new];
        [self.admin addObjectsFromArray:value];
    }else if ([key isEqual:@"owner"]) {
        self.owner = value;
    }else{
        [super setValue:value forKey:key];
    }

}

@end
