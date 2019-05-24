//
//  WCTakePhotoButton.h
//  HXDIDCardRecognitionPlugin
//
//  Created by zhangjikuan on 2018/11/30.
//  Copyright © 2018 com.winchannel.net. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN
typedef enum {
    WCTakePhotoButtonCamera,
    WCTakePhotoButtonVideo,
}WCTakePhotoButtonType;

typedef enum {
    WCTakePhotoButtonStateNormal,
    WCTakePhotoButtonStateSelected
}WCTakePhotoButtonState;

@class WCTakePhotoButton;
typedef  void(^WCClickedBlock)(WCTakePhotoButton *button);

@interface WCTakePhotoButton : UIView

@property (nonatomic, assign) WCTakePhotoButtonType type;
@property (nonatomic, assign) WCTakePhotoButtonState state;
@property (nonatomic, copy)   WCClickedBlock clickedBlock;

@end

NS_ASSUME_NONNULL_END
