//
//  NBAclBase.m
//
//  COPYRIGHT (C) 2014 NEC CORPORATION
//

#import "Headers/NBAclBase.h"
#import "NBErrorFactory.h"
#import "Common.h"

@implementation NBAclBase

#pragma mark -
#pragma mark public methods

- (instancetype)init {
    self = [super init];
    if (self != nil) {
        self.r = [[NSMutableArray alloc] init];
        self.w = [[NSMutableArray alloc] init];
        self.u = [[NSMutableArray alloc] init];
        self.c = [[NSMutableArray alloc] init];
        self.d = [[NSMutableArray alloc] init];
    }
    return self;
}

- (BOOL)addEntry:(NSString *)entry
    permission:(NBAclPermission)permission {
    NSMutableArray *target = [self targetArray:permission];

    if (target == nil) {
        DLog(@"Invalid Permission.");

        return NO;
    }

    if (![target containsObject:entry]) {
        [target addObject:entry];
    }
    else {
        DLog(@"the entry %@ already exists.", entry);
    }

    return YES;
}

- (BOOL)removeEntry:(NSString *)entry
    permission:(NBAclPermission)permission {
    NSMutableArray *target = [self targetArray:permission];

    if (target == nil) {
        DLog(@"Invalid Permission.");
        return NO;
    }

    if ([target containsObject:entry]) {
        [target removeObject:entry];
    }
    else {
        DLog(@"the entry %@ does not exist.", entry);
    }

    return YES;
}

- (NSDictionary *)entriesDictionary {
    NSDictionary *ret = [self dictionaryWithValuesForKeys:[self aclKeys]];
    return ret;
}

- (void)setEntriesDictionary:(NSDictionary *)dictionary {
    [self setValuesForKeysWithDictionary:dictionary];
}

#pragma mark -
#pragma mark private methods

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
        case NBAclReadable:
            target = self.r;
            break;

        case NBAclWritable:
            target = self.w;
            break;

        case NBAclCreatable:
            target = self.c;
            break;

        case NBAclDeletable:
            target = self.d;
            break;

        case NBAclUpdatable:
            target = self.u;
            break;

        default:
            target = nil;
            break;
    }

    return target;
}

/**
 *  要素キー取得
 *
 *  独自クラスの要素として取り扱うプロパティ名の一覧をNSArray型で返却する。
 *
 *  @return 要素キーを含めた配列
 */
- (NSArray *)aclKeys {
    return @[@"r", @"w", @"c", @"u", @"d"];
}

- (void)setValue:(id)value forUndefinedKey:(NSString *)key {
    DLog(@"Error: setting unknown key: %@ with data: %@", key, value);
}

- (void)setValue:(id)value forKey:(NSString *)key {

    if ([key isEqual:@"c"]) {
        self.c = [NSMutableArray new];
        [self.c addObjectsFromArray:value];
    } else if ([key isEqual:@"r"]) {
        self.r = [NSMutableArray new];
        [self.r addObjectsFromArray:value];
    } else if ([key isEqual:@"u"]) {
        self.u = [NSMutableArray new];
        [self.u addObjectsFromArray:value];
    } else if ([key isEqual:@"d"]) {
        self.d = [NSMutableArray new];
        [self.d addObjectsFromArray:value];
    } else if ([key isEqual:@"w"]) {
        self.w = [NSMutableArray new];
        [self.w addObjectsFromArray:value];
    }

}

@end
