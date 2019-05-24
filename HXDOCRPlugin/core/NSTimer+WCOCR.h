//
//  NSTimer+WCORC.h
//  HXDOCRPlugin
//
//  Created by zhangjikuan on 2018/12/29.
//  Copyright © 2018 com.winchannel.net. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface NSTimer (WCOCR)

@end
@interface NSTimer (OCRUnRetain)
+ (NSTimer *)wc_scheduledTimerWithTimeInterval:(NSTimeInterval)inerval
                                           repeats:(BOOL)repeats
                                             block:(void(^)(NSTimer *timer))block;

@end
NS_ASSUME_NONNULL_END
