//
//  WCAVCaptureViewController.m
//  HXDIDCardRecognitionPlugin
//
//  Created by zhangjikuan on 2018/11/30.
//  Copyright © 2018 com.winchannel.net. All rights reserved.
//

#define kORCBottomDistanceHeight (WCOCR_isPhoneX?34:0)

#import "WCAVCaptureViewController.h"
#import "WCIDCardScaningView.h"
#import "WCIDInfo.h"
#import "UIImage+WCOCR.h"
#import "UIAlertController+WCOCR.h"
#import "WCRectManager.h"
#import "WCTakePhotoButton.h"
#import "WCOCRRecognize.h"
#import <TesseractOCR/TesseractOCR.h>
#import <AVFoundation/AVFoundation.h>

static NSString *const kStatusBarAppearanceKey = @"UIViewControllerBasedStatusBarAppearance";

@interface WCAVCaptureViewController () <AVCaptureVideoDataOutputSampleBufferDelegate,
    AVCaptureMetadataOutputObjectsDelegate>

/// 摄像头设备
@property (nonatomic,strong ) AVCaptureDevice            *device;
/// AVCaptureSession对象来执行输入设备和输出设备之间的数据传递
@property (nonatomic,strong ) AVCaptureSession           *session;
/// 输出格式
@property (nonatomic,strong ) NSNumber                   *outPutSetting;
/// 出流对象
@property (nonatomic,strong ) AVCaptureVideoDataOutput   *videoDataOutput;
/// 元数据（用于人脸识别）
@property (nonatomic,strong ) AVCaptureMetadataOutput    *metadataOutput;
/// 预览图层
@property (nonatomic,strong ) AVCaptureVideoPreviewLayer *previewLayer;
/// 手电筒
@property (nonatomic, strong) UIButton                   *torchButton;
/// 人脸检测框区域
@property (nonatomic,assign) CGRect faceDetectionFrame;
/// 队列
@property (nonatomic,strong) dispatch_queue_t queue;
/// 是否打开手电筒
@property (nonatomic,assign,getter = isTorchOn) BOOL torchOn;
/// 扫描视图
@property (nonatomic, strong) WCIDCardScaningView *scanView;
/// 关闭按钮
@property (nonatomic, strong) UIButton *closeBtn;
/// 拍照按钮
@property (nonatomic, strong) WCTakePhotoButton *takePhotoButton;
@end

@implementation WCAVCaptureViewController

-(void)viewDidLoad {
    [super viewDidLoad];
#if TARGET_IPHONE_SIMULATOR
    NSLog(@"模拟器无法使用，请使用真机测试");
#else
    [self addSubviews];
#endif

}

-(void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];

    // 将AVCaptureViewController的navigationBar调为透明
    [[[self.navigationController.navigationBar subviews] objectAtIndex:0] setAlpha:0];

    // 每次展现AVCaptureViewController的界面时，都检查摄像头使用权限
    [self checkAuthorizationStatus];
    self.torchOn = NO;
    self.navigationController.navigationBar.hidden = YES;
    [self setStatusBarHiddenState:YES];
    // 禁用返回手势
    if ([self.navigationController respondsToSelector:@selector(interactivePopGestureRecognizer)]) {
        self.navigationController.interactivePopGestureRecognizer.enabled = NO;
    }
}

-(void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    // 将AVCaptureViewController的navigationBar调为不透明
    [[[self.navigationController.navigationBar subviews] objectAtIndex:0] setAlpha:1];
    [self stopSession];
}

- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
    [self setStatusBarHiddenState:NO];
    if ([self.navigationController respondsToSelector:@selector(interactivePopGestureRecognizer)]) {
        self.navigationController.interactivePopGestureRecognizer.enabled = YES;
    }

}

- (BOOL)prefersStatusBarHidden {
    return YES;
}

- (void)setStatusBarHiddenState:(BOOL)isHidden
{
    NSNumber *isVCBasedStatusBarAppearanceNum = [[NSBundle mainBundle]
                                                 objectForInfoDictionaryKey:kStatusBarAppearanceKey];
    if(isVCBasedStatusBarAppearanceNum.boolValue == NO)
    {
        [[UIApplication sharedApplication] setStatusBarHidden:isHidden withAnimation:NO];
    } else {
        if ([self respondsToSelector:@selector(setNeedsStatusBarAppearanceUpdate)])
        {
            [self prefersStatusBarHidden];
            [self performSelector:@selector(setNeedsStatusBarAppearanceUpdate)];
        } else {
            [[UIApplication sharedApplication] setStatusBarHidden:isHidden withAnimation:NO];
        }
    }
}

- (void)addSubviews{
    // 添加预览图层
    [self.view.layer addSublayer:self.previewLayer];
    // 添加自定义的扫描界面
    [self.view addSubview:self.scanView];
    // 设置脸部识别区域
    self.faceDetectionFrame = self.scanView.facePathRect;
    [self.view addSubview:self.closeBtn];
    if (!_recognizeIdCardEnable) {
        [self.view addSubview:self.takePhotoButton];
    }
    [self.view addSubview:self.torchButton];

}
#pragma mark - 运行session
// session开始，即输入设备和输出设备开始数据传递
- (void)runSession {
    if (![self.session isRunning]) {
        dispatch_async(self.queue, ^{
            [self.session startRunning];
        });
    }
}

#pragma mark - 停止session
// session停止，即输入设备和输出设备结束数据传递
-(void)stopSession {
    if ([self.session isRunning]) {
        dispatch_async(self.queue, ^{
            [self.session stopRunning];
        });
    }
}

#pragma mark - 打开／关闭手电筒
-(void)turnOnOrOffTorch {
    self.torchOn = !self.isTorchOn;
    self.torchButton.selected = !self.torchButton.selected;

    if ([self.device hasTorch]){ // 判断是否有闪光灯
        [self.device lockForConfiguration:nil];// 请求独占访问硬件设备
        if (self.isTorchOn) {
            [self.device setTorchMode:AVCaptureTorchModeOn];
        } else {
            [self.device setTorchMode:AVCaptureTorchModeOff];
        }
        [self.device unlockForConfiguration];// 请求解除独占访问硬件设备
    } else {
        UIAlertAction *okAction = [self defaultAlertActionWithTitle:@"确定"];
        [self alertControllerWithTitle:@"提示"
                               message:@"您的设备没有闪光设备，不能提供手电筒功能，请检查"
                              okAction:okAction
                          cancelAction:nil];
    }
}
#pragma mark 关闭按钮
-(void)close {
    [self stopSession];

    dispatch_async(dispatch_get_main_queue(), ^{
        if (self.navigationController) {
            [self.navigationController popViewControllerAnimated:YES];
        } else {
            [self dismissViewControllerAnimated:YES completion:nil];
        }
    });
}

#pragma mark - 检测摄像头权限
-(void)checkAuthorizationStatus {
    AVAuthorizationStatus authorizationStatus = [AVCaptureDevice authorizationStatusForMediaType:AVMediaTypeVideo];

    switch (authorizationStatus) {
        case AVAuthorizationStatusNotDetermined:
            [self showAuthorizationNotDetermined];
            break;// 用户尚未决定授权与否，那就请求授权
        case AVAuthorizationStatusAuthorized:
            [self showAuthorizationAuthorized];
            break;// 用户已授权，那就立即使用
        case AVAuthorizationStatusDenied:
            [self showAuthorizationDenied];
            break;// 用户明确地拒绝授权，那就展示提示
        case AVAuthorizationStatusRestricted:
            [self showAuthorizationRestricted];
            break;// 无法访问相机设备，那就展示提示
    }
}

#pragma mark - 相机使用权限处理
#pragma mark 用户还未决定是否授权使用相机
-(void)showAuthorizationNotDetermined {
    __weak __typeof__(self) weakSelf = self;
    [AVCaptureDevice requestAccessForMediaType:AVMediaTypeVideo
                             completionHandler:^(BOOL granted) {
        granted? [weakSelf runSession]: [weakSelf showAuthorizationDenied];
    }];
}

#pragma mark 被授权使用相机
-(void)showAuthorizationAuthorized {
    [self runSession];
}

#pragma mark 未被授权使用相机
-(void)showAuthorizationDenied {
    NSString *title = @"相机未授权";
    NSString *message = @"请到系统的“设置-隐私-相机”中授权此应用使用您的相机";
    UIAlertAction *okAction = [self defaultAlertActionWithTitle:@"去设置"
                                                         hander:^(UIAlertAction *action) {
                                                             [self openAppSettings];
                                                         }];
    UIAlertAction *cancelAction = [self defaultAlertActionWithTitle:@"取消"];
    [self alertControllerWithTitle:title message:message okAction:okAction cancelAction:cancelAction];
}

- (void)openAppSettings {
    NSURL *url = [NSURL URLWithString:UIApplicationOpenSettingsURLString];
    [[UIApplication sharedApplication] openURL:url];
}
#pragma mark 使用相机设备受限
-(void)showAuthorizationRestricted {
    NSString *title = @"相机设备受限";
    NSString *message = @"请检查您的手机硬件或设置";
    UIAlertAction *okAction = [self defaultAlertActionWithTitle:@"确定"];
    [self alertControllerWithTitle:title
                           message:message
                          okAction:okAction
                      cancelAction:nil];
}

#pragma mark - 展示UIAlertController

- (UIAlertAction *)defaultAlertActionWithTitle:(NSString *)title{
    return [self defaultAlertActionWithTitle:title hander:nil];
}

- (UIAlertAction *)defaultAlertActionWithTitle:(NSString *)title
                                        hander:(void (^ )(UIAlertAction *action))handler
{
    UIAlertAction *action = [UIAlertAction actionWithTitle:title
                                                     style:UIAlertActionStyleDefault
                                                   handler:handler];
    return action;
}

-(void)alertControllerWithTitle:(NSString *)title
                        message:(NSString *)message
                       okAction:(UIAlertAction *)okAction
                   cancelAction:(UIAlertAction *)cancelAction {

    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:title
                                                                             message:message
                                                                            okAction:okAction
                                                                        cancelAction:cancelAction];
    alertController.view.transform = CGAffineTransformMakeRotation(M_PI * 0.5);
    for (UIView *view in alertController.view.subviews) {
        view.transform = CGAffineTransformMakeRotation(M_PI * 0.5);
    }
    [self presentViewController:alertController animated:YES completion:nil];
}

#pragma mark - AVCaptureMetadataOutputObjectsDelegate
#pragma mark 从输出的元数据中捕捉人脸
-(void)captureOutput:(AVCaptureOutput *)captureOutput
        didOutputMetadataObjects:(NSArray *)metadataObjects
      fromConnection:(AVCaptureConnection *)connection{
    if (metadataObjects.count) {
        AVMetadataMachineReadableCodeObject *metadataObject = metadataObjects.firstObject;

        AVMetadataObject *transformedMetadataObject = [self.previewLayer transformedMetadataObjectForMetadataObject:metadataObject];
        CGRect faceRegion = transformedMetadataObject.bounds;
        if (metadataObject.type == AVMetadataObjectTypeFace) {
            NSLog(@"是否包含头像：%d, facePathRect: %@, faceRegion: %@",CGRectContainsRect(self.faceDetectionFrame, faceRegion),NSStringFromCGRect(self.faceDetectionFrame),NSStringFromCGRect(faceRegion));

            if (CGRectContainsRect(self.faceDetectionFrame, faceRegion) ) {
                // 只有当人脸区域的确在小框内时，才再去做捕获此时的这一帧图像
                // 为videoDataOutput设置代理，程序就会自动调用下面的代理方法，捕获每一帧图像
                if (!self.videoDataOutput.sampleBufferDelegate) {
                    [self.videoDataOutput setSampleBufferDelegate:self queue:self.queue];
                }
            }
        }
    }
}

#pragma mark - AVCaptureVideoDataOutputSampleBufferDelegate
#pragma mark 从输出的数据流捕捉单一的图像帧
// AVCaptureVideoDataOutput获取实时图像，这个代理方法的回调频率很快，几乎与手机屏幕的刷新频率一样快
-(void)captureOutput:(AVCaptureOutput *)captureOutput
        didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer
      fromConnection:(AVCaptureConnection *)connection {
    if ([self.outPutSetting isEqualToNumber:[NSNumber numberWithInt:kCVPixelFormatType_420YpCbCr8BiPlanarVideoRange]]
        || [self.outPutSetting isEqualToNumber:[NSNumber numberWithInt:kCVPixelFormatType_420YpCbCr8BiPlanarFullRange]]) {
        CVImageBufferRef imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer);

        if ([captureOutput isEqual:self.videoDataOutput]) {
            // 身份证信息识别
            [self IDCardRecognit:imageBuffer];
            // 身份证信息识别完毕后，就将videoDataOutput的代理去掉，
            //防止频繁调用AVCaptureVideoDataOutputSampleBufferDelegate方法而引起的“混乱”
            if (self.videoDataOutput.sampleBufferDelegate) {
                [self.videoDataOutput setSampleBufferDelegate:nil queue:self.queue];
            }
        }
    } else {
        NSLog(@"输出格式不支持");
    }
}

#pragma mark - 身份证信息识别
- (UIImage *)getSubImageWithImageBuffer:(CVImageBufferRef)imageBuffer {
    size_t width= CVPixelBufferGetWidth(imageBuffer);// 1920
    size_t height = CVPixelBufferGetHeight(imageBuffer);// 1080
    CGRect effectRect = [WCRectManager getEffectImageRect:CGSizeMake(width, height)];
    CGRect rect = [WCRectManager getGuideFrame:effectRect];
    UIImage *image = [UIImage getImageStream:imageBuffer];
    UIImage *subImage = [UIImage getSubImage:rect inImage:image];
    return subImage;
}

- (void)IDCardRecognit:(CVImageBufferRef)imageBuffer {
    CVBufferRetain(imageBuffer);

    // Lock the image buffer
    if (CVPixelBufferLockBaseAddress(imageBuffer, 0) == kCVReturnSuccess) {

        WCIDInfo *iDInfo = [[WCIDInfo alloc] init];

        if (!_recognizeIdCardEnable) {
            // 手动拍照逻辑
            AudioServicesPlaySystemSound(1108);
            [self stopSession];

            UIImage *subImage = [self getSubImageWithImageBuffer:imageBuffer];
            UIImage *rcImage = [[WCOCRRecognize shareInstance] opencvScanCard:subImage];
            if (rcImage == nil) {
                // 提示请对准身份证
                [self showForceIDCardAlert];
            } else {
                [self callBackWithIdImage:subImage];
            }

        } else if (_recognizeIdCardEnable){
            // 自动拍照逻辑
            UIImage *subImage = [self getSubImageWithImageBuffer:imageBuffer];
            NSString *idNum = [[WCOCRRecognize shareInstance] tesseractRecognizeIDNumberImage:subImage];

            if ([WCIDInfo validateIDCardNumber:idNum]) {
                //此处只做身份证判断，身份证合法后即可拍照
                iDInfo.num = idNum;
                iDInfo.address = [[WCOCRRecognize shareInstance] tesseractRecognizeAdressImage:subImage];
                iDInfo.name = [[WCOCRRecognize shareInstance] tesseractRecognizeIDNameImage:subImage];

                AudioServicesPlaySystemSound(1108);
                [self stopSession];
                [self callBackWith:subImage idCardInfo:iDInfo];
            }
        }

        CVPixelBufferUnlockBaseAddress(imageBuffer, 0);
    }

    CVBufferRelease(imageBuffer);
}

- (void)callBackWithIdImage:(UIImage *)image {
    dispatch_async(dispatch_get_main_queue(), ^{
        if (self.delegate &&
            [self.delegate respondsToSelector:@selector(wc_idCardImagePickerController:
                                                        didFinishPickingWithImage:)]) {

            [self.delegate wc_idCardImagePickerController:self
                                didFinishPickingWithImage:image];
        }

        [self close];
    });
}

- (void)callBackWith:(UIImage *)image idCardInfo:(WCIDInfo *)iDInfo {

    dispatch_async(dispatch_get_main_queue(), ^{
        if (self.delegate &&
            [self.delegate respondsToSelector:@selector(wc_idCardImagePickerController:
                                                        didFinishPickingWithImage:
                                                        andIdCardInfo:)]) {

            [self.delegate wc_idCardImagePickerController:self
                                didFinishPickingWithImage:image
                                            andIdCardInfo:iDInfo];
        }
        [self close];
    });
}

- (void)showForceIDCardAlert {
    dispatch_async(dispatch_get_main_queue(), ^{

        UIAlertAction *okAction = [self defaultAlertActionWithTitle:@"确定"
                                                             hander:^(UIAlertAction *action) {
                                                                 [self runSession];
                                                             }];
        [self alertControllerWithTitle:@"温馨提示"
                               message:@"请按照提示对准身份证卡片"
                              okAction:okAction
                          cancelAction:nil];
    });

}

- (BOOL)shouldAutorotate{
    return NO;
}

- (UIInterfaceOrientationMask)supportedInterfaceOrientations{
    return UIInterfaceOrientationMaskPortrait;

}
#pragma mark - 懒加载
#pragma mark device
-(AVCaptureDevice *)device {
    if (_device == nil) {
        _device = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];

        NSError *error = nil;
        if ([_device lockForConfiguration:&error]) {
            if ([_device isSmoothAutoFocusSupported]) {// 平滑对焦
                _device.smoothAutoFocusEnabled = YES;
            }

            if ([_device isFocusModeSupported:AVCaptureFocusModeContinuousAutoFocus]) {// 自动持续对焦
                _device.focusMode = AVCaptureFocusModeContinuousAutoFocus;
            }

            if ([_device isExposureModeSupported:AVCaptureExposureModeContinuousAutoExposure ]) {// 自动持续曝光
                _device.exposureMode = AVCaptureExposureModeContinuousAutoExposure;
            }

            if ([_device isWhiteBalanceModeSupported:AVCaptureWhiteBalanceModeContinuousAutoWhiteBalance]) {// 自动持续白平衡
                _device.whiteBalanceMode = AVCaptureWhiteBalanceModeContinuousAutoWhiteBalance;
            }

            [_device unlockForConfiguration];
        }
    }

    return _device;
}

#pragma mark outPutSetting
-(NSNumber *)outPutSetting {
    if (_outPutSetting == nil) {
        _outPutSetting = @(kCVPixelFormatType_420YpCbCr8BiPlanarVideoRange);
    }

    return _outPutSetting;
}

#pragma mark metadataOutput
-(AVCaptureMetadataOutput *)metadataOutput {
    if (_metadataOutput == nil) {
        _metadataOutput = [[AVCaptureMetadataOutput alloc]init];
        if (_recognizeIdCardEnable) {
            // 如果使用自动识别技术 开启人脸
            [_metadataOutput setMetadataObjectsDelegate:self queue:self.queue];
        }
    }

    return _metadataOutput;
}

#pragma mark videoDataOutput
-(AVCaptureVideoDataOutput *)videoDataOutput {
    if (_videoDataOutput == nil) {
        _videoDataOutput = [[AVCaptureVideoDataOutput alloc] init];

        _videoDataOutput.alwaysDiscardsLateVideoFrames = YES;
        _videoDataOutput.videoSettings = @{(id)kCVPixelBufferPixelFormatTypeKey:self.outPutSetting};
    }

    return _videoDataOutput;
}

#pragma mark session
-(AVCaptureSession *)session {
    if (_session == nil) {
        _session = [[AVCaptureSession alloc] init];

        _session.sessionPreset = AVCaptureSessionPresetHigh;

        // 2、设置输入：由于模拟器没有摄像头，因此最好做一个判断
        NSError *error = nil;
        AVCaptureDeviceInput *input = [AVCaptureDeviceInput deviceInputWithDevice:self.device error:&error];

        if (error) {
            UIAlertAction *okAction = [self defaultAlertActionWithTitle:@"确定"];
            [self alertControllerWithTitle:@"没有摄像设备"
                                   message:error.localizedDescription
                                  okAction:okAction
                              cancelAction:nil];
        }else {
            if ([_session canAddInput:input]) {
                [_session addInput:input];
            }

            if ([_session canAddOutput:self.videoDataOutput]) {
                [_session addOutput:self.videoDataOutput];
            }

            if ([_session canAddOutput:self.metadataOutput]) {
                [_session addOutput:self.metadataOutput];
                // 输出格式要放在addOutPut之后，否则奔溃
                self.metadataOutput.metadataObjectTypes = @[AVMetadataObjectTypeFace];
            }
        }
    }

    return _session;
}

#pragma mark previewLayer
-(AVCaptureVideoPreviewLayer *)previewLayer {
    if (_previewLayer == nil) {
        _previewLayer = [[AVCaptureVideoPreviewLayer alloc] initWithSession:self.session];

        _previewLayer.frame = self.view.frame;
        _previewLayer.videoGravity = AVLayerVideoGravityResizeAspectFill;
    }

    return _previewLayer;
}

#pragma mark queue
-(dispatch_queue_t)queue {
    if (_queue == nil) {
        _queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
    }

    return _queue;
}

#pragma mak WCIDCardScaningView

- (WCIDCardScaningView *)scanView {
    if (_scanView == nil) {
        if (_recognizeIdCardEnable) {
            _scanView= [[WCIDCardScaningView alloc] initWithFrame:self.view.frame
                                                             showScanline:YES];
        } else {
            _scanView= [[WCIDCardScaningView alloc] initWithFrame:self.view.frame
                                                             showScanline:NO];
        }
    }
    return _scanView;
}
#pragma mark - closeButton
- (UIButton *)closeBtn {
    if (_closeBtn == nil) {

        _closeBtn = [UIButton buttonWithType:UIButtonTypeCustom];
        [_closeBtn setImage:[UIImage hxd_orc_imageNamed:@"idcard_back"]
                   forState:UIControlStateNormal];
        CGFloat closeBtnWidth = 60;
        CGFloat closeBtnHeight = closeBtnWidth;
        CGRect viewFrame = self.view.frame;
        _closeBtn.frame = (CGRect){CGRectGetMaxX(viewFrame) - closeBtnWidth,
            CGRectGetMaxY(viewFrame) - closeBtnHeight, closeBtnWidth, closeBtnHeight};

        [_closeBtn addTarget:self
                      action:@selector(close)
            forControlEvents:UIControlEventTouchUpInside];
    }
    return _closeBtn;
}

#pragma mark -takePhotoButton
- (WCTakePhotoButton *)takePhotoButton {
    if (_takePhotoButton == nil) {
        _takePhotoButton= [[WCTakePhotoButton alloc] initWithFrame:CGRectMake(0, 0, 60, 60)];
        _takePhotoButton.frame = (CGRect){self.view.center.x- 30,CGRectGetMaxY(self.view.frame)-60-kORCBottomDistanceHeight, 60, 60};
        __weak typeof(self) weakSelf = self;
        [_takePhotoButton setClickedBlock:^(WCTakePhotoButton *button) {
            _recognizeIdCardEnable = NO;
            if (!weakSelf.videoDataOutput.sampleBufferDelegate) {
                [weakSelf.videoDataOutput setSampleBufferDelegate:weakSelf queue:weakSelf.queue];
            }
        }];
    }
    return _takePhotoButton;
}
#pragma mark -torchButton
- (UIButton *)torchButton {
    if (_torchButton == nil) {
        _torchButton = [UIButton buttonWithType:UIButtonTypeCustom];
        [_torchButton setBackgroundImage:[UIImage hxd_orc_imageNamed:@"torch_close"]
                                forState:UIControlStateNormal];
        [_torchButton setBackgroundImage:[UIImage hxd_orc_imageNamed:@"torch_open"]
                                forState:UIControlStateSelected];
        CGSize size = [UIImage hxd_orc_imageNamed:@"torch_open"].size;
        _torchButton.frame = (CGRect){self.view.center.x- size.height*0.5, 30, size.width, size.height};
        [_torchButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        [_torchButton setBackgroundColor:[UIColor clearColor]];
        _torchButton.transform = CGAffineTransformMakeRotation(M_PI * 0.5);
        [_torchButton addTarget:self
                         action:@selector(turnOnOrOffTorch)
               forControlEvents:UIControlEventTouchUpInside];
    }
    return _torchButton;
}
@end

