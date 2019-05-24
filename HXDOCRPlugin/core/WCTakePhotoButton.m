//
//  WCTakePhotoButton.m
//  HXDIDCardRecognitionPlugin
//
//  Created by zhangjikuan on 2018/11/30.
//  Copyright © 2018 com.winchannel.net. All rights reserved.
//

#import "WCTakePhotoButton.h"
#define LINEWIDTHRATE 0.12f

@interface WCTakePhotoButton ()

@property (nonatomic,strong) CAShapeLayer *inCircleLayer;
@property (nonatomic,assign) CGFloat lineWidth;

@end

@implementation WCTakePhotoButton

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
        self.lineWidth = frame.size.width*LINEWIDTHRATE;
        //边框
        CAShapeLayer *circleBorder = [CAShapeLayer layer];
        circleBorder.frame = self.bounds;
        circleBorder.borderWidth = self.lineWidth;
        circleBorder.borderColor = [UIColor whiteColor].CGColor;
        circleBorder.cornerRadius = frame.size.width/2;
        [self.layer addSublayer:circleBorder];

        //内部圆形
        self.inCircleLayer = [CAShapeLayer layer];
        _inCircleLayer.frame = CGRectMake(self.lineWidth+2, self.lineWidth+2, frame.size.width-(self.lineWidth+2)*2, frame.size.height-(self.lineWidth+2)*2);
        _inCircleLayer.cornerRadius = _inCircleLayer.frame.size.width/2;
        _inCircleLayer.backgroundColor = [UIColor whiteColor].CGColor;
        [self.layer addSublayer:_inCircleLayer];

        _type = WCTakePhotoButtonCamera;
        _state = WCTakePhotoButtonStateNormal;
    }
    return self;
}
-(void)setType:(WCTakePhotoButtonType)type{

    if(_type != type){
        _type =  type;

        [self.inCircleLayer removeAllAnimations];
        CABasicAnimation *animation = [CABasicAnimation animationWithKeyPath:@"backgroundColor"];
        animation.duration = 0.3f;
        animation.fromValue = (id)self.inCircleLayer.backgroundColor;
        if(type == WCTakePhotoButtonCamera){


            animation.toValue = (id)[UIColor whiteColor].CGColor;
            [self.inCircleLayer addAnimation:animation forKey:@"backgroundColor"];
            self.inCircleLayer.backgroundColor = [UIColor whiteColor].CGColor;


        }else if(type == WCTakePhotoButtonVideo){

            animation.toValue = (id)[UIColor redColor].CGColor;
            [self.inCircleLayer addAnimation:animation forKey:@"backgroundColor"];
            self.inCircleLayer.backgroundColor = [UIColor redColor].CGColor;
        }
        [self setState:WCTakePhotoButtonStateNormal];

    }
}

-(void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event{
    self.inCircleLayer.opacity = 0.5;
}
-(void)touchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event{
    NSLog(@"%@",NSStringFromSelector(_cmd));
}
-(void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event{
    self.inCircleLayer.opacity = 1.0f;


    if(self.type==WCTakePhotoButtonVideo){
        [self setState:(self.state+1)%2];
        if(self.clickedBlock){
            self.clickedBlock(self);
        }
    }else if(self.type == WCTakePhotoButtonCamera){
        dispatch_async(dispatch_get_main_queue(), ^{
            if(self.clickedBlock){
                self.clickedBlock(self);
            }
        });

    }
}
-(void)setState:(WCTakePhotoButtonState)state{
    if(_state != state){
        if(self.type == WCTakePhotoButtonVideo){

            CABasicAnimation *animation = [CABasicAnimation animationWithKeyPath:@"cornerRadius"];
            CABasicAnimation *animationBounds = [CABasicAnimation animationWithKeyPath:@"bounds"];
            animation.duration = animationBounds.duration = 0.2f;
            animation.fromValue = @(self.inCircleLayer.cornerRadius);
            CGRect bounds = self.inCircleLayer.bounds;
            animationBounds.fromValue = [NSValue valueWithCGRect:bounds];
            if(state == WCTakePhotoButtonStateSelected){
                animation.toValue = @(5);
                bounds.size.width = self.bounds.size.width*0.4;
                bounds.size.height = self.bounds.size.height*0.4;
                animationBounds.toValue = [NSValue valueWithCGRect:bounds];
                self.inCircleLayer.cornerRadius = 5.0f;
                self.inCircleLayer.bounds = bounds;
            }else if(state == WCTakePhotoButtonStateNormal){

                bounds.size.width = self.frame.size.width-(self.lineWidth+2)*2;
                bounds.size.height = self.frame.size.height-(self.lineWidth+2)*2;
                animationBounds.toValue = [NSValue valueWithCGRect:bounds];
                animation.toValue = @(bounds.size.width/2);
                self.inCircleLayer.cornerRadius = bounds.size.width/2;
                self.inCircleLayer.bounds = bounds;
            }
            [self.inCircleLayer addAnimation:animation forKey:@"cornerRadius"];
            [self.inCircleLayer addAnimation:animationBounds forKey:@"bounds"];
            CAAnimationGroup *group = [CAAnimationGroup animation];
            group.duration = 0.2f;
//            group.delegate = self;
            group.removedOnCompletion = YES;
            group.animations = @[animationBounds,animation];
            [self.inCircleLayer addAnimation:group forKey:@"group"];
        }
        _state = state;
    }
}


@end
