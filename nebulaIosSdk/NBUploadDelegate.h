//
//  NBUploadDelegate.h
//
//  COPYRIGHT (C) 2014 NEC CORPORATION
//


#import <Foundation/Foundation.h>

#import "NBURLSession.h"

@interface NBUploadDelegate : NSObject <NSURLSessionDelegate, NSURLSessionTaskDelegate, NSURLSessionDataDelegate>

/**
 *  Background Transferで必要になるパラメータをタスクIDごとに格納する(アップロード用)
 */
@property (nonatomic) NSMutableDictionary *uploadParams;

@end
