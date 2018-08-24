//
//  NBDownloadDelegate.h
//
//  COPYRIGHT (C) 2014 NEC CORPORATION
//


#import <Foundation/Foundation.h>

#import "NBURLSession.h"

@interface NBDownloadDelegate : NSObject <NSURLSessionDelegate, NSURLSessionTaskDelegate, NSURLSessionDownloadDelegate>

/**
 *  Background Transferで必要になるパラメータをタスクIDごとに格納する(ダウンロード用)
 */
@property (nonatomic) NSMutableDictionary *downloadParams;

@end
