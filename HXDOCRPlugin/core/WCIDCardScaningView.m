//
//  WCIDCardScaningView.m
//  HXDIDCardRecognitionPlugin
//
//  Created by zhangjikuan on 2018/11/30.
//  Copyright © 2018 com.winchannel.net. All rights reserved.
//

#import "WCIDCardScaningView.h"
#import "UIImage+WCOCR.h"
#import "NSTimer+WCOCR.h"

@interface WCIDCardScaningView () {
    CAShapeLayer *_IDCardScanningWindowLayer;
    NSTimer *_timer;
}
/**
 是否显示扫描线 默认为NO
 */
@property (nonatomic, assign) BOOL showScanline;
@end

@implementation WCIDCardScaningView

- (instancetype)initWithFrame:(CGRect)frame showScanline:(BOOL)showScanline {
    if (self = [super initWithFrame:frame]) {
        self.backgroundColor = [UIColor clearColor];
        _showScanline = showScanline;

        // 添加扫描窗口
        [self addScaningWindow];
        // 添加定时器
        [self addTimer];
    }

    return self;
}
- (instancetype)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
        self.backgroundColor = [UIColor clearColor];
        _showScanline = NO;

        // 添加扫描窗口
        [self addScaningWindow];
        // 添加定时器
        [self addTimer];
    }

    return self;
}
#pragma mark - 添加扫描窗口
-(void)addScaningWindow {
    // 中间包裹线
    _IDCardScanningWindowLayer = [CAShapeLayer layer];
    _IDCardScanningWindowLayer.position = self.layer.position;
    CGFloat width = iPhone5or5cor5sorSE? 240: (iPhone6or6sor7? 270: 300);
    _IDCardScanningWindowLayer.bounds = (CGRect){CGPointZero, {width, width * 1.574}};
    _IDCardScanningWindowLayer.cornerRadius = 15;
    _IDCardScanningWindowLayer.borderColor = [UIColor whiteColor].CGColor;
    _IDCardScanningWindowLayer.borderWidth = 1.5;
    [self.layer addSublayer:_IDCardScanningWindowLayer];

    // 最里层镂空
    UIBezierPath *transparentRoundedRectPath = [UIBezierPath bezierPathWithRoundedRect:_IDCardScanningWindowLayer.frame cornerRadius:_IDCardScanningWindowLayer.cornerRadius];

    // 最外层背景
    UIBezierPath *path = [UIBezierPath bezierPathWithRect:self.frame];
    [path appendPath:transparentRoundedRectPath];
    [path setUsesEvenOddFillRule:YES];

    CAShapeLayer *fillLayer = [CAShapeLayer layer];
    fillLayer.path = path.CGPath;
    fillLayer.fillRule = kCAFillRuleEvenOdd;
    fillLayer.fillColor = [UIColor blackColor].CGColor;
    fillLayer.opacity = 0.6;

    [self.layer addSublayer:fillLayer];

    CGFloat facePathWidth = iPhone5or5cor5sorSE? 125: (iPhone6or6sor7? 150: 180);

    CGFloat facePathHeight = facePathWidth * 0.812;
    CGRect rect = _IDCardScanningWindowLayer.frame;
    self.facePathRect = (CGRect){CGRectGetMaxX(rect) - facePathWidth - 35,
        CGRectGetMaxY(rect) - facePathHeight - 25,facePathWidth,facePathHeight};

    // 提示标签
    CGPoint center = self.center;
    center.x = CGRectGetMaxX(_IDCardScanningWindowLayer.frame) + 20;

    // 人像
    if (_showScanline){
        UIImageView *headIV = [[UIImageView alloc] initWithFrame:_facePathRect];
        headIV.image = [UIImage hxd_orc_imageNamed:@"idcard_first_head"];
        headIV.transform = CGAffineTransformMakeRotation(M_PI * 0.5);
        headIV.contentMode = UIViewContentModeScaleAspectFill;
        [self addSubview:headIV];
        [self addTipLabelWithText:@"将身份证人像面置于此区域内，头像对准，扫描" center:center];
    } else {
        [self addTipLabelWithText:@"将身份证置于此区域内，边框对准，拍摄" center:center];
    }
}

#pragma mark - 添加提示标签
-(void )addTipLabelWithText:(NSString *)text center:(CGPoint)center {
    UILabel *tipLabel = [[UILabel alloc] init];
    tipLabel.text = text;
    tipLabel.textColor = [UIColor whiteColor];
    tipLabel.textAlignment = NSTextAlignmentCenter;
    tipLabel.transform = CGAffineTransformMakeRotation(M_PI * 0.5);
    [tipLabel sizeToFit];
    tipLabel.center = center;
    [self addSubview:tipLabel];
}

#pragma mark - 添加定时器
-(void)addTimer {
    __weak typeof(self) weakSelf = self;
    _timer = [NSTimer wc_scheduledTimerWithTimeInterval:0.02
                                                repeats:_showScanline
                                                  block:^(NSTimer * _Nonnull timer) {
                                                      [weakSelf timerFire:nil];
                                                  }];
    [_timer fire];
}

-(void)timerFire:(id)notice {
    [self setNeedsDisplay];
}

-(void)dealloc {
    [_timer invalidate];
}

- (void)drawRect:(CGRect)rect {

    if (_showScanline) {
        // 人像提示框
        UIBezierPath *facePath = [UIBezierPath bezierPathWithRect:_facePathRect];
        facePath.lineWidth = 1.5;
        [[UIColor whiteColor] set];
        [facePath stroke];
        rect = _IDCardScanningWindowLayer.frame;
        CGContextRef context = UIGraphicsGetCurrentContext();
        // 水平扫描线
        static CGFloat moveX = 0;
        static CGFloat distanceX = 0;

        CGContextBeginPath(context);
        CGContextSetLineWidth(context, 2);
        CGContextSetRGBStrokeColor(context,0.3,0.8,0.3,0.8);
        CGPoint p1, p2;// p1, p2 连成水平扫描线;

        moveX += distanceX;
        if (moveX >= CGRectGetWidth(rect) - 2) {
            distanceX = -2;
        } else if (moveX <= 2){
            distanceX = 2;
        }

        p1 = CGPointMake(CGRectGetMaxX(rect) - moveX, rect.origin.y);
        p2 = CGPointMake(CGRectGetMaxX(rect) - moveX, rect.origin.y + rect.size.height);

        CGContextMoveToPoint(context,p1.x, p1.y);
        CGContextAddLineToPoint(context, p2.x, p2.y);
        CGContextStrokePath(context);
    }
}


@end
