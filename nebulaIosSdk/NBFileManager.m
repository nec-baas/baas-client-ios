//
//  NBFileManager.m
//
//  COPYRIGHT (C) 2014 NEC CORPORATION
//


#import "NBFileManager.h"
#import "NBErrorFactory.h"
#import "Common.h"

/**
 *  インスタンス変数
 */
@interface NBFileManager ()
@property (nonatomic) NSFileManager *defaultManager;    // NSFileManagerのインスタンス
@property (nonatomic) NSString *parentPath;             // Nebulaフォルダのパス
@end

@implementation NBFileManager

/**
 *  定数
 */
static NSString * const NBParentFolderName = @"/Nebula";

#pragma mark -
#pragma mark public methods

+ (instancetype)sharedManager {
    // 本クラスはライブラリ内でのみ使用されるため、allocWithZoneとcopyWithZoneのオーバーライドは省略する

    static id _sharedManager = nil;
    static dispatch_once_t oncePredicate;
    dispatch_once(&oncePredicate, ^{
        _sharedManager = [[self alloc] init];
    });

    return _sharedManager;
}

- (BOOL)saveToPlist:(NSString *)plist data:(NSDictionary *)data error:(NSError **)error {
    NSString *plistPath = [self plistPath:plist];
    BOOL result = YES;

    @synchronized(self) {
        if (![self.defaultManager fileExistsAtPath:self.parentPath]) {
            // Nebulaフォルダがなければ、作成する
            result = [self.defaultManager createDirectoryAtPath:self.parentPath withIntermediateDirectories:YES attributes:nil error:error];
        }
    }

    if (!result) {
        // フォルダ作成に失敗した場合は、処理失敗を返す
        return NO;
    }

    @synchronized(self) {
        // プロパティリスト保存
        result = [NSKeyedArchiver archiveRootObject:data toFile:plistPath];
    }

    if (!result) {
        // プロパティリスト保存に失敗した場合は、処理失敗を返す
        *error = [NBErrorFactory makeErrorForCode:NBErrorUnsaved];
        return NO;
    }

    return YES;
}

- (NSDictionary *)loadFromPlist:(NSString *)plist error:(NSError **)error {
    NSString *plistPath = [self plistPath:plist];

    if (![self fileExistsAtPlistPath:plistPath error:error]) {
        // プロパティリストが存在しない場合は、nilを返す
        return nil;
    }

    NSDictionary *dict;    // 現状はNSDictionary型限定
    @synchronized(self) {
        //プロパティリスト読み出し
        dict = [NSKeyedUnarchiver unarchiveObjectWithFile:plistPath];
    }

    return dict;
}

- (id)objectFromPlist:(NSString *)plist key:(id)key error:(NSError **)error {
    NSDictionary *dict = [self loadFromPlist:plist error:error];
    return dict[key];
}

- (BOOL)deletePlist:(NSString *)plist error:(NSError **)error {
    NSString *plistPath = [self plistPath:plist];

    if (![self.defaultManager fileExistsAtPath:plistPath]) {
        // プロパティリストが存在しない場合は、処理成功を返す
        return YES;
    }

    BOOL result = YES;
    @synchronized(self) {
        // プロパティリスト削除
        result = [self.defaultManager removeItemAtPath:plistPath error:error];
    }

    return result;
}

- (instancetype)init {
    self = [super init];

    if (self) {
        // インスタンス取得
        self.defaultManager = [NSFileManager defaultManager];

        // Nebulaフォルダのパス設定
        NSString *path = [NSSearchPathForDirectoriesInDomains(NSApplicationSupportDirectory, NSUserDomainMask, YES) lastObject];
        self.parentPath = [path stringByAppendingPathComponent:NBParentFolderName];
        DLog(@"parentPath: %@",self.parentPath);
    }

    return self;
}

#pragma mark -
#pragma mark private methods

/**
 *  プロパティリストパス取得
 *
 *  プロパティリストのパスを取得する。
 *
 *  @param plist プロパティリスト名
 *
 *  @return プロパティリストのパス
 */
- (NSString *)plistPath:(NSString *)plist {
    return [self.parentPath stringByAppendingPathComponent:plist];
}

/**
 *  プロパティリスト存在チェック
 *
 *  プロパティリストが存在するかをチェックし、存在しない場合はエラーを設定する。
 *
 *  @param plistPath プロパティリストのパス
 *  @param error     エラー内容
 *
 *  @return プロパティリスト存在有無（YES:存在する/NO:存在しない）
 */
- (BOOL)fileExistsAtPlistPath:(NSString *)plistPath error:(NSError **)error {
    if (![self.defaultManager fileExistsAtPath:plistPath]) {
        // プロパティリストファイルが存在しない場合
        *error = [NBErrorFactory makeErrorForCode:NBErrorNoInfomation];
        return NO;
    }

    return YES;
}

@end
