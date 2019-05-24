//
//  WCRectManager.h
//  HXDIDCardRecognitionPlugin
//
//  Created by zhangjikuan on 2018/11/30.
//  Copyright © 2018 com.winchannel.net. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface WCRectManager : NSObject

@property (nonatomic, assign)CGRect subRect;

+ (CGRect)getEffectImageRect:(CGSize)size;

+ (CGRect)getGuideFrame:(CGRect)rect;

+ (int)docode:(unsigned char *)pbBuf len:(int)tLen;

+ (CGRect)getCorpCardRect:(int)width
                   height:(int)height
                guideRect:(CGRect)guideRect
                charCount:(int) charCount;

+ (char *)getNumbers;

@end

NS_ASSUME_NONNULL_END
