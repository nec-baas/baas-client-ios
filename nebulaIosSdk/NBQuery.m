//
//  NBQuery.m
//
//  COPYRIGHT (C) 2014 NEC CORPORATION
//


#import "Headers/NBQuery.h"
#import "Headers/NBClause.h"

@interface NBQuery ()
/**
 *  ソート条件
 */
@property (nonatomic) NSMutableArray *sortOrdersArray;
@end

@implementation NBQuery

@synthesize limit;
@synthesize skip;
@synthesize queryCount;
@synthesize sortOrdersArray;
@synthesize clause;


#pragma mark -
#pragma mark public methods

/**
 *  イニシャライザ
 *  limit/skipは負の値を設定(検索条件として指定しない)
 *  queryCountは通常カウントを行う条件とする
 *
 *  @return 初期化済みインスタンス
 */
- (instancetype)init {
    if (self = [super init]) {
        self.limit = -10;
        self.skip = -1;
        self.queryCount = YES;
        self.sortOrdersArray = nil;
        self.clause = nil;
    }
    return self;
}

+ (NBQuery *)queryWithClause:(NBClause *)clause {
    NBQuery *query = [[NBQuery alloc] init];
    query.clause = clause;
    return query;
}

- (void)setSortOrderWithKey:(NSString *)key isAscend:(BOOL)order {
    if (!self.sortOrdersArray) {
        self.sortOrdersArray = [NSMutableArray array];
    }

    NSNumber *boolObject = @(order);
    NSDictionary *sortCondition = @{ key : boolObject };

    [self.sortOrdersArray addObject:sortCondition];
}

- (NSArray *)sortOrder {
    // 条件を外部に公開
    return self.sortOrdersArray;
}

@end
