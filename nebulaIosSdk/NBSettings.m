//
//  NBSettings.m
//
//  COPYRIGHT (C) 2014 NEC CORPORATION
//


#import "Headers/NBSettings.h"

// like a class variables
static NBOperationMode _operationMode = NBOperationModeOperation;

@implementation NBSettings

#pragma mark -
#pragma mark public methods

+ (NBOperationMode)operationMode {
    return _operationMode;
}

+ (void)setOperationMode:(NBOperationMode)operationMode {
    _operationMode = operationMode;
}

@end
