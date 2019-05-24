//
//  UIAlertController+WCORC.h
//  HXDOCRPlugin
//
//  Created by zhangjikuan on 2018/12/29.
//  Copyright © 2018 com.winchannel.net. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface UIAlertController (WCORC)
// 创建AlertController
+(instancetype)alertControllerWithTitle:(NSString *)title
                                message:(NSString *)message
                               okAction:(UIAlertAction *)okAction
                           cancelAction:(UIAlertAction *)cancelAction;

// 创建ActionSheetController
+(instancetype)actionSheetControllerWithTitle:(NSString *)title
                                      message:(NSString *)message
                                     okAction:(UIAlertAction *)okAction
                                 cancelAction:(UIAlertAction *)cancelAction;
@end

NS_ASSUME_NONNULL_END
