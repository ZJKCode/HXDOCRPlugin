//
//  WCIDCardScaningView.h
//  HXDIDCardRecognitionPlugin
//
//  Created by zhangjikuan on 2018/11/30.
//  Copyright © 2018 com.winchannel.net. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN
#define WCOCR_WIDTH [UIScreen mainScreen].bounds.size.width
#define WCOCR_HEIGHT [UIScreen mainScreen].bounds.size.height
#define iPhone5or5cor5sorSE (WCOCR_WIDTH == 568.0 || WCOCR_HEIGHT == 568.0)
#define iPhone6or6sor7 (WCOCR_WIDTH == 667.0 ||  WCOCR_HEIGHT == 667.0)
#define iPhone6Plusor6sPlusor7Plus (WCOCR_WIDTH == 736.0 ||  WCOCR_HEIGHT == 736.0)
#define WCOCR_isPhoneX (WCOCR_WIDTH == 375 && WCOCR_HEIGHT == 812)

@interface WCIDCardScaningView : UIView

@property (nonatomic, assign) CGRect facePathRect;

- (instancetype)initWithFrame:(CGRect)frame showScanline:(BOOL)showScanline;

@end

NS_ASSUME_NONNULL_END
