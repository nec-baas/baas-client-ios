//
//  NBClause.m
//
//  COPYRIGHT (C) 2014 NEC CORPORATION
//

#import "Headers/NBClause.h"

@interface NBClause ()
@property (nonatomic) NSMutableDictionary *conditions;
@end

@implementation NBClause

@synthesize conditions;

#pragma mark -
#pragma mark public methods


- (NSDictionary *)dictionaryValue {
    return self.conditions;
}

+ (NBClause *)equals:(NSString *)key value:(id)value {
    // equals条件の設定
    NBClause *clauseInstance = [self clauseWithKey:key value:value];

    return clauseInstance;
}

+ (NBClause *)notEquals:(NSString *)key value:(id)value {
    // notEquals条件の設定
    NSDictionary *notEqualsDictionary = @{ @"$ne" : value };

    NBClause *clauseInstance = [self clauseWithKey:key value:notEqualsDictionary];

    return clauseInstance;
}

+ (NBClause *)lessThan:(NSString *)key value:(id)value {
    // LessThan条件の設定
    NSDictionary *lessThanDictionary = @{ @"$lt" : value };

    NBClause *clauseInstance = [self clauseWithKey:key value:lessThanDictionary];

    return clauseInstance;
}

+ (NBClause *)lessThanOrEqual:(NSString *)key value:(id)value {
    // LessThanOrEqual条件の設定
    NSDictionary *lessThanOrEqualDictionary = @{ @"$lte" : value };

    NBClause *clauseInstance = [self clauseWithKey:key value:lessThanOrEqualDictionary];

    return clauseInstance;
}

+ (NBClause *)greaterThan:(NSString *)key value:(id)value {
    // GraterThan条件の設定
    NSDictionary *greaterThanDictionary = @{ @"$gt" : value };

    NBClause *clauseInstance = [self clauseWithKey:key value:greaterThanDictionary];

    return clauseInstance;
}

+ (NBClause *)greaterThanOrEqual:(NSString *)key value:(id)value {
    // GraterThanOrEquals条件の設定
    NSDictionary *greaterThanOrEqualDictionary = @{ @"$gte" : value };

    NBClause *clauseInstance = [self clauseWithKey:key value:greaterThanOrEqualDictionary];

    return clauseInstance;
}

+ (NBClause *)in:(NSString *)key value:(NSArray *)values {
    // in条件の設定
    NSDictionary *inDictionary = @{ @"$in" : values };

    NBClause *clauseInstance = [self clauseWithKey:key value:inDictionary];

    return clauseInstance;
}

+ (NBClause *)all:(NSString *)key value:(NSArray *)values {
    // all条件の設定
    NSDictionary *allDictionary = @{ @"$all" : values };

    NBClause *clauseInstance = [self clauseWithKey:key value:allDictionary];

    return clauseInstance;
}

+ (NBClause *)exists:(NSString *)key value:(BOOL)value {
    // exists条件の設定
    NSNumber *boolValue = @(value);
    NSDictionary *existsDictionary = @{ @"$exists" : boolValue };

    NBClause *clauseInstance = [self clauseWithKey:key value:existsDictionary];

    return clauseInstance;
}

+ (NBClause *)regex:(NSString *)key expression:(NSString *)value options:(NBRegexCaseOptions)options {
    // regex条件の設定
    NSMutableDictionary *regexDictionary = [NSMutableDictionary dictionaryWithObject:value forKey:@"$regex"];

    // optionの設定処理
    NBRegexCaseOptions optionsRange = NBRegexCaseNone;
    optionsRange |= NBRegexCaseInsensitivity;
    optionsRange |= NBRegexCaseMultiLine;
    optionsRange |= NBRegexCaseExtended;
    optionsRange |= NBRegexCaseDotMultiLine;

    NBRegexCaseOptions localOption = (options > optionsRange) ? NBRegexCaseNone : options;

    NSMutableString *optionString = [NSMutableString string];

    // NBRegexCaseInsensitivityフラグ有効
    if ((localOption & NBRegexCaseInsensitivity) != 0) {
        [optionString appendString:@"i"];
    }
    if ((localOption & NBRegexCaseMultiLine) != 0) {
        [optionString appendString:@"m"];
    }
    if ((localOption & NBRegexCaseExtended) != 0) {
        [optionString appendString:@"x"];
    }
    if ((localOption & NBRegexCaseDotMultiLine) != 0) {
        [optionString appendString:@"s"];
    }
    // 有効なオプションが設定されている場合のみdictionaryに追加
    if (optionString.length > 0) {
        regexDictionary[@"$options"] = optionString;
    }

    NBClause *clauseInstance = [self clauseWithKey:key value:regexDictionary];

    return clauseInstance;
}

+ (NBClause *)and:(NSArray *)clauses {
    // and条件の設定
    NSMutableDictionary *andDictionary = [NSMutableDictionary dictionary];
    NSMutableArray *andList = [NSMutableArray array];

    for (NBClause *aClause in clauses) {
        [andList addObject:[aClause dictionaryValue]];
    }

    andDictionary[@"$and"] = andList;

    NBClause *clauseInstance = [[NBClause alloc] initClauseWithDictionary:andDictionary];

    return clauseInstance;
}

+ (NBClause *)or:(NSArray *)clauses {
    // or条件の設定
    NSMutableDictionary *orDictionary = [NSMutableDictionary dictionary];
    NSMutableArray *orList = [NSMutableArray array];

    for (NBClause *aClause in clauses) {
        [orList addObject:[aClause dictionaryValue]];
    }

    orDictionary[@"$or"] = orList;

    NBClause *clauseInstance = [[NBClause alloc] initClauseWithDictionary:orDictionary];

    return clauseInstance;
}

+ (NBClause *)not:(NBClause *)clause {
    // 全条件をまとめるdictionary
    NSMutableDictionary *wholeConditionDictionary = [NSMutableDictionary dictionary];

    // 指定されたClauseの条件取得
    NSMutableDictionary *baseConditions = [[clause dictionaryValue] mutableCopy];

    for (id key in baseConditions) {
        // 条件に指定されている要素を一つづつ取り出し
        id aCondition = baseConditions[key];
        // not条件の設定
        NSMutableDictionary *notDictionary = [NSMutableDictionary dictionary];
        notDictionary[@"$not"] = aCondition;
        wholeConditionDictionary[key] = notDictionary;
    }

    NBClause *clauseInstance = [[NBClause alloc] initClauseWithDictionary:wholeConditionDictionary];

    return clauseInstance;
}

#pragma mark -
#pragma mark private method

/**
 *
 *  指定のdictionaryでClauseを初期化する
 *
 *  @param dictionary 初期値のdictionary
 *
 *  @return 初期化したClause
 */
- (instancetype)initClauseWithDictionary:(NSDictionary *)dictionary {
    if ((self = [self init])) {
        self.conditions = [dictionary mutableCopy];
    }
    return self;
}

/**
 *  ClauseをDictionaryで指定した条件に設定する
 *
 *  @param dictionary 検索条件
 */
- (void)setConditionWithDictionary:(NSDictionary *)dictionary {
    self.conditions = [dictionary mutableCopy];
}

/**
 *  指摘のキーに対し、Dictionaryの要素をValueに設定したClauseを生成する。
 *
 *  @param key   新規のキー
 *  @param value キーに対応するDictionary
 *
 *  @return 指定条件で更新したClauseのインスタンス
 */
+ (NBClause *)clauseWithKey:(NSString *)key value:(id)value {
    NSDictionary *conditionDictionary = @{ key : value };

    NBClause *clauseInstance = [[NBClause alloc] initClauseWithDictionary:conditionDictionary];

    return clauseInstance;
}

/**
 *  copyを実行するためのメソッド
 *  ライブラリ内で呼び出しを行う必要はない。
 *
 *  @param zone メモリをアロケートするzone
 *
 *  @return コピーしたインスタンス
 */
- (id)copyWithZone:(NSZone *)zone {
    // enable copy method
    NBClause *copyInstance = [[[self class] allocWithZone:zone] initClauseWithDictionary:self.conditions];

    return copyInstance;
}

@end
