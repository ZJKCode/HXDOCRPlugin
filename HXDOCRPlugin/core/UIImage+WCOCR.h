//
//  UIImage+WCOCR.h
//  HXDOCRPlugin
//
//  Created by zhangjikuan on 2018/12/29.
//  Copyright © 2018 com.winchannel.net. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface UIImage (WCOCR)

+ (UIImage *)imageFromSampleBuffer:(CMSampleBufferRef)sampleBuffer;

+ (UIImage *)getImageStream:(CVImageBufferRef)imageBuffer;

+ (UIImage *)getSubImage:(CGRect)rect inImage:(UIImage *)image;

- (UIImage *)originalImage;

- (UIImage *)imageCompressForWidth:(UIImage *)sourceImage targetWidth:(CGFloat)defineWidth;

@end

@interface UIImage (Bundle)

+ (UIImage *)hxd_orc_imageNamed:(NSString *)name;

@end

NS_ASSUME_NONNULL_END
