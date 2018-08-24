//
//  NBAPNSFields.m
//
//  COPYRIGHT (C) 2014 NEC CORPORATION
//

#import "Headers/NBAPNSFields.h"
#import "Common.h"

@implementation NBAPNSFields

#pragma mark -
#pragma mark public methods

+ (NBAPNSFields *)createFields {
    return [NBAPNSFields new];
}

- (NSDictionary *)dictionaryValue {
    // オブジェクトをNSDictionary型で取得 (nilオブジェクトはNSNullに変換される)
    NSDictionary *dict = [self dictionaryWithValuesForKeys:[self fieldsKeys]];
    NSMutableDictionary *mdict = [NSMutableDictionary dictionary];
    NSNull *nul = [NSNull null];

    for (id key in dict) {
        // NSNullを省く
        if (dict[key] && dict[key] != nul) {
            if ([key isEqualToString:@"contentAvailable"]) {
                mdict[@"content-available"] = dict[key];
            }
            else {
                mdict[key] = dict[key];
            }
        }
    }

    return mdict;
}

- (instancetype)init {
    self = [super init];

    if (self) {
        self.badge = nil;
        self.sound = nil;
        self.contentAvailable = nil;
        self.category = nil;
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
- (NSArray *)fieldsKeys {
    return @[@"badge", @"sound", @"contentAvailable", @"category"];
}

- (void)setValue:(id)value forUndefinedKey:(NSString *)key {
    DLog(@"Error: setting unknown key: %@ with data: %@", key, value);
}

@end
