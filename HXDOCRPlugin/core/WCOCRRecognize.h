//
//  WCORCRecognize.h
//  HXDOCRPlugin
//
//  Created by zhangjikuan on 2018/12/3.
//  Copyright © 2018 com.winchannel.net. All rights reserved.
//

#import <Foundation/Foundation.h>

@class UIImage;
@class WCIDInfo;

NS_ASSUME_NONNULL_BEGIN

typedef enum : NSUInteger {
    /** 身份证号码 */
    WCIDCardOutlineTypeIDNum,
    /** 身份证地址 */
    WCIDCardOutlineTypeAdress,
    /** 身份证姓名 */
    WCIDCardOutlineTypeName,
} WCIDCardOutlineType; // 身份证轮廓类型


/**
 识别图片完成后回调

 @param text 识别信息
 */
typedef void (^ORCCompleteBlock)(NSString *text);

/**
 识别身份成功后回调Block

 @param idInfo 身份信息instance
 */
typedef void(^RecognizeCompletionBlcok)(WCIDInfo *idInfo);


/**
 识别图片类
 */
@interface WCOCRRecognize : NSObject

/**
 使用单例创建 instance

 @return instance type
 */
+ (instancetype)shareInstance;


/**
 异步识别身份证卡片信息

 @param IDImage 身份原图
 @param completion 识别成功后主线程回调
 */
- (void)recognizeIDCard:(UIImage *)IDImage
             completion:(RecognizeCompletionBlcok)completion;


/**
 异步识别身份证单条信息

 @param IDImage 身份证原图
 @param type 信息类型
 @param compleate 识别成功后主线程回调
 */
- (void)recognizeIDCard:(UIImage *)IDImage
           withCardType:(WCIDCardOutlineType)type
               complete:(ORCCompleteBlock)compleate;


/**
 tesserac异步识别图片信息

 @param image 图片原图
 @param complete 识别成功后主线程回调
 */
- (void)tesseractRecognizeImage:(UIImage *)image
                       complete:(ORCCompleteBlock)complete;

/*** 调用识别方法 ***/
/**
 截取身份证姓名图片

 @param image 身份证原图
 @return 身份证姓名图片
 */
- (UIImage *)opencvScanCardName:(UIImage *)image;

/**
 截取身份证地址区域图片

 @param image 身份证原图
 @return 地址区域图片
 */
- (UIImage *)opencvScanCardAdress:(UIImage *)image;

/**
 截取身份证号码区域图片

 @param image 身份证原图
 @return 身份证号码区域图片
 */
- (UIImage *)opencvScanCard:(UIImage *)image;

/**
 仅仅识别身份证号码

 @param image 身份证原图
 @return 身份证号码
 */
- (NSString *)tesseractRecognizeIDNumberImage:(UIImage *)image;

/**
 仅仅识别身份证住址

 @param image 身份证原图
 @return 身份证号码
 */
- (NSString *)tesseractRecognizeAdressImage:(UIImage *)image;

/**
 仅仅识别身份证上的姓名

 @param image 身份证原图
 @return 身份证上的姓名
 */
- (NSString *)tesseractRecognizeIDNameImage:(UIImage *)image;

/**
 识别身份证信息 目前包括 姓名、身份证号码、住址 三种信息

 @param image 身份证原图
 @return 身份证号码信息
 */
- (WCIDInfo *)tesseractRecognizeImage:(UIImage *)image;

@end

NS_ASSUME_NONNULL_END
