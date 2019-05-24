//
//  WCAVCaptureViewController.h
//  HXDIDCardRecognitionPlugin
//
//  Created by zhangjikuan on 2018/11/30.
//  Copyright © 2018 com.winchannel.net. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "WCIDInfo.h"

NS_ASSUME_NONNULL_BEGIN

@class WCAVCaptureViewController;

@protocol WCAVCaptureViewControllerDelegate <NSObject>

@optional

/**
 默认拍照成功后执行

 @param controller WCIDCardImagePickerController
 @param image 截取身份证之后的图片
 */
- (void)wc_idCardImagePickerController:(WCAVCaptureViewController *)controller
             didFinishPickingWithImage:(UIImage *)image;

/**
 开启自动识别拍照成功后的图片

 @param controller WCIDCardImagePickerController
 @param image 截取身份证之后的图片
 @param info 身份证信息
 */
- (void)wc_idCardImagePickerController:(WCAVCaptureViewController *)controller
             didFinishPickingWithImage:(UIImage *)image
                         andIdCardInfo:(WCIDInfo *)info;


@end

@interface WCAVCaptureViewController : UIViewController

@property (nonatomic, weak) id<WCAVCaptureViewControllerDelegate> delegate;

/**
 拍照过程中是否开启识别身份证功能,开启后，识别身份证号成功会自动拍照，然后返回
 YES 开启 默认为不开启
 */
@property (nonatomic, assign) BOOL recognizeIdCardEnable;

@end

NS_ASSUME_NONNULL_END
