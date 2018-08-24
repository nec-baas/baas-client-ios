//
//  NBErrorCode.h
//
//  COPYRIGHT (C) 2014 NEC CORPORATION
//


#ifndef nebulaIosSdk_NBErrorCode_h
#define nebulaIosSdk_NBErrorCode_h

/**
 *  エラーコード一覧
 */
typedef NS_ENUM (NSInteger,NBErrorCode) {
    /**
     *  Precondition Error
     */
    NBErrorPreconditionError NS_SWIFT_NAME(preconditionError) = 1000,
    /**
     *  Invalid Argument Error
     */
    NBErrorInvalidArgumentError NS_SWIFT_NAME(invalidArgumentError),
    /**
     *  Request Error
     */
    NBErrorRequestError NS_SWIFT_NAME(requestError) = 1099,
    /**
     *  No information available.
     */
    NBErrorNoInfomation NS_SWIFT_NAME(noInformation) = 1100,
    /**
     *  Unsaved.
     */
    NBErrorUnsaved NS_SWIFT_NAME(unsaved),
    /**
     *  Unable to retrieve valid session token
     */
    NBErrorInvalidSessionToken NS_SWIFT_NAME(invalidSessionToken) = 1200,
    /**
     *  Failed to download
     */
    NBErrorFailedToDownload NS_SWIFT_NAME(failedToDownload)
};


#endif
