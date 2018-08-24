//
//  NBSettings.h
//
//  COPYRIGHT (C) 2014 NEC CORPORATION
//


#import <Foundation/Foundation.h>

/**
 *  共通設定クラス
 *
 *  アプリ全体の設定値のうち、アプリ起動後にいつでも設定可能なパラメータを保持する。
 */
@interface NBSettings : NSObject

/**
 *  動作モード
 */
typedef NS_ENUM (NSInteger, NBOperationMode) {
    /**
     *  通常運用モード
     */
    NBOperationModeOperation,
    /**
     *  デバッグモード
     */
    NBOperationModeDebug
};

/**
 *  動作モードを取得する。
 *
 *  @return 動作モード
 */
+ (NBOperationMode)operationMode;

/**
 *  動作モードを設定する。
 *
 *  @param operationMode 動作モード
 */
+ (void)setOperationMode:(NBOperationMode)operationMode;

@end
