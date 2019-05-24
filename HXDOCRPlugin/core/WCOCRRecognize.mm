//
//  WCOCRRecognize.m
//  HXDOCRPlugin
//
//  Created by zhangjikuan on 2018/12/3.
//  Copyright © 2018 com.winchannel.net. All rights reserved.
//

#import "WCOCRRecognize.h"
#import <opencv2/opencv.hpp>
#import <opencv2/imgproc/types_c.h>
#import <opencv2/imgcodecs/ios.h>
#import <TesseractOCR/TesseractOCR.h>

#import "WCIDInfo.h"

@interface WCOCRRecognize()
{
    int idNumHeight;
}

@end

@implementation WCOCRRecognize

+ (instancetype)shareInstance {
    static WCOCRRecognize *instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[WCOCRRecognize alloc] init];
    });
    return instance;
}

- (void)recognizeIDCard:(UIImage *)IDImage
             completion:(RecognizeCompletionBlcok)completion{
    WCIDInfo *idInfo = [[WCIDInfo alloc] init];
    dispatch_group_t group = dispatch_group_create();
    dispatch_queue_t queue = dispatch_queue_create("com.winchannel.orcPlugin.net", DISPATCH_QUEUE_CONCURRENT);

    dispatch_group_async(group, queue, ^{
        idInfo.num = [self tesseractRecognizeIDNumberImage:IDImage];
    });

    dispatch_group_async(group, queue, ^{
        idInfo.address = [self tesseractRecognizeAdressImage:IDImage];
    });

    dispatch_group_async(group, queue, ^{
        idInfo.name = [self tesseractRecognizeIDNameImage:IDImage];
    });

    dispatch_group_notify(group, queue, ^{
        dispatch_async(dispatch_get_main_queue(), ^{
            // 回到主线程
            if (completion) {
                completion(idInfo);
            }
        });
    });
}

- (void)recognizeIDCard:(UIImage *)IDImage
           withCardType:(WCIDCardOutlineType)type
               complete:(ORCCompleteBlock)compleate;
{
    UIImage *image = [self opencvScanCardWithType:type andImage:IDImage];

    [self tesseractRecognizeImage:image
                         complete:compleate];

}
- (void)tesseractRecognizeImage:(UIImage *)image complete:(ORCCompleteBlock)compleate {
    if (image == nil) {
        NSLog(@"图片没有处理成功");
        return;
    }
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
        NSString *text = [self tesseractRecognizeResultImage:image];
        //执行回调
        dispatch_async(dispatch_get_main_queue(), ^{
            if (compleate) {
                compleate(text);
            }
        });
    });
}

- (UIImage *)opencvScanCardWithType:(WCIDCardOutlineType)type andImage:(UIImage *)image{

    //将UIImage转换成Mat
    cv::Mat resultImage;
    UIImageToMat(image, resultImage);

    //转为灰度图
    cv::cvtColor(resultImage, resultImage, CV_RGB2GRAY);

    //利用阈值二值化
    cv::adaptiveThreshold(resultImage, resultImage, 255, CV_ADAPTIVE_THRESH_GAUSSIAN_C, CV_THRESH_BINARY, 31, 40);

    //腐蚀，填充（腐蚀是让黑色点变大）
    cv::Mat erodeElement = getStructuringElement(cv::MORPH_RECT, cv::Size(30,30));
    cv::erode(resultImage, resultImage, erodeElement);

    //轮廊检测
    std::vector<std::vector<cv::Point>> contours; //定义一个容器来存储所有检测到的轮廊
    std::vector<cv::Vec4i> hierarchy;

    // 轮廓检测函数
    cv::findContours(resultImage, contours,hierarchy, CV_RETR_TREE, CV_CHAIN_APPROX_NONE, cvPoint(0, 0));

    /*  取出身份证号码区域  */
    std::vector<cv::Rect> rects;
    cv::Rect numberRect = cv::Rect(0,0,0,0);

    // 定义并直接赋值第一个元素
    std::vector<std::vector<cv::Point>>::const_iterator itContours = contours.begin();

    // 遍历容器内的所有元素
    for (; itContours != contours.end(); ++itContours) {
        cv::Rect rect = cv::boundingRect(*itContours);

        // rect放入rects容器存储
        rects.push_back(rect);

//        printf("X:%d - Y:%d - width:%d - height:%d \n",rect.x,rect.y,rect.width,rect.height);

        // 算法原理
        switch (type) {
            case WCIDCardOutlineTypeIDNum:
            {
                if (rect.width > numberRect.width && rect.width > rect.height * 4) {
                    numberRect = rect;
                    idNumHeight = rect.height;
                    NSLog(@"WCIDCardOutlineTypeIDNum %d",rect.width/rect.height);
                }
            }
                break;
            case WCIDCardOutlineTypeAdress:
            {
                if (rect.width > numberRect.width && (rect.y/rect.x>=1)&&
                    rect.width>3*rect.height &&rect.height>idNumHeight) {
                    numberRect = rect;
                    NSLog(@"WCIDCardOutlineTypeAdress %d",rect.width/rect.height);
                }

            }
                break;
            case WCIDCardOutlineTypeName:
            {

                if (rect.width > numberRect.width && (rect.x/rect.y)>=2 &&
                    (rect.width > rect.height*2) && rect.height<2*idNumHeight) {
                    numberRect = rect;
                    NSLog(@"WCIDCardOutlineTypeName %d",rect.width/rect.height);
                }

            }
                break;
            default:
                break;
        }
    }
 

    // 原图 -> Mat
    cv::Mat matImage;
    UIImageToMat(image, matImage);

    // 取到对应Rect的目标图像
    resultImage = matImage(numberRect);

    // 将目标图像灰度处理
    cv::cvtColor(resultImage, resultImage, cv::COLOR_BGR2GRAY);

    // 二值化
    cv::adaptiveThreshold(resultImage, resultImage, 255, CV_ADAPTIVE_THRESH_GAUSSIAN_C, CV_THRESH_BINARY, 31, 40);

    UIImage *newImage = MatToUIImage(resultImage);

    return newImage;

}

- (UIImage *)opencvScanCardAdress:(UIImage *)image {
    return [self opencvScanCardWithType:WCIDCardOutlineTypeAdress andImage:image];
}

- (UIImage *)opencvScanCardName:(UIImage *)image {
    return [self opencvScanCardWithType:WCIDCardOutlineTypeName andImage:image];
}

- (UIImage *)opencvScanCard:(UIImage *)image {

    return [self opencvScanCardWithType:WCIDCardOutlineTypeIDNum andImage:image];
}

- (NSString *)tesseractRecognizeIDNumberImage:(UIImage *)image {

    UIImage *idNumImage = [self opencvScanCard:image];
    if (idNumImage) {
        return  [self tesseractRecognizeResultImage:idNumImage];
    }
    return @"";
}

- (NSString *)tesseractRecognizeAdressImage:(UIImage *)image {
    UIImage *adress = [self opencvScanCardAdress:image];
    if (adress) {
        return  [self tesseractRecognizeResultImage:adress];
    }
    return @"";
}

- (NSString *)tesseractRecognizeIDNameImage:(UIImage *)image {
    UIImage *name = [self opencvScanCardName:image];
    if (name) {
        return  [self tesseractRecognizeResultImage:name];
    }
    return @"";
}

- (WCIDInfo *)tesseractRecognizeImage:(UIImage *)image {

    WCIDInfo *info = [[WCIDInfo alloc] init];
    info.num = [self tesseractRecognizeIDNumberImage:image];
    info.address = [self tesseractRecognizeAdressImage:image];
    info.name = [self tesseractRecognizeIDNameImage:image];

    return info;
}

- (NSString *)tesseractRecognizeResultImage:(UIImage *)image {
    G8Tesseract *tesseract = [[G8Tesseract alloc] initWithLanguage:@"eng+chi_sim"];
    tesseract.image = [image g8_blackAndWhite];
    tesseract.engineMode = G8OCREngineModeTesseractOnly;
    tesseract.maximumRecognitionTime = 30.0;
    tesseract.pageSegmentationMode = G8PageSegmentationModeAuto;

    [tesseract recognize];
    NSLog(@"处理成功 %@",tesseract.recognizedText);

    return tesseract.recognizedText;
}
@end
