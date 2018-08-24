//
//  NBAcl.h
//
//  COPYRIGHT (C) 2014 NEC CORPORATION
//


#import "NBAclBase.h"

NS_ASSUME_NONNULL_BEGIN

/**
 *  ACLクラス
 *
 *  バケットやオブジェクト自体のACLを指定するクラス
 */

@interface NBAcl : NBAclBase

/**
 *  管理者ユーザリスト
 */
@property (nonatomic) NSMutableArray<NSString *> *admin;

/**
 *  オーナユーザID
 */
@property (nonatomic, nullable) NSString *owner;

@end

NS_ASSUME_NONNULL_END
