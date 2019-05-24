//
//  NSTimer+WCORC.m
//  HXDOCRPlugin
//
//  Created by zhangjikuan on 2018/12/29.
//  Copyright © 2018 com.winchannel.net. All rights reserved.
//

#import "NSTimer+WCOCR.h"

@implementation NSTimer (WCOCR)

@end

@implementation NSTimer (OCRUnRetain)
+ (NSTimer *)wc_scheduledTimerWithTimeInterval:(NSTimeInterval)inerval
                                           repeats:(BOOL)repeats
                                             block:(void(^)(NSTimer *timer))block {

    return [NSTimer scheduledTimerWithTimeInterval:inerval
                                            target:self
                                          selector:@selector(hxdorc_blcokInvoke:)
                                          userInfo:[block copy]
                                           repeats:repeats];

}

+ (void)hxdorc_blcokInvoke:(NSTimer *)timer {
    void (^block)(NSTimer *timer) = timer.userInfo;

    if (block) {
        block(timer);
    }
}
@end
