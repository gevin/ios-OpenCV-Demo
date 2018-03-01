//
//  BackProjectVC.m
//  OpenCV_Demo
//
//  Created by GevinChen on 2018/2/25.
//  Copyright © 2018年 GevinChen. All rights reserved.
//

#import "HistDemoVC.h"

@interface HistDemoVC ()
{
    UIImage *_imageObj;
    UIImage *_imageScene;
    BOOL _initLoad;
}

@end

@implementation HistDemoVC

- (void)viewDidLoad {
    [super viewDidLoad];
    _imageObj = [UIImage imageNamed:@"wallet.png"];
    _imageScene = [UIImage imageNamed:@"wallet_scene2.png"];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    if(!_initLoad){
        _initLoad= YES;
        [self histdemo:_imageScene];
        [self backprojectObj:_imageObj];
    }
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/
- (IBAction)btnTakePhotoClicked:(id)sender {
    typeof(self) w_self = self;
    [self removeAllItem];
    [self takePhoto:^(UIImage *image) {
        [w_self histdemo:image];
    }];
    
}

- (IBAction)btnBackClicked:(id)sender {
    
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)histdemo:(UIImage*)image
{
    cv::Mat sceneM;
    cv::Mat sceneM_gray;
    cv::Mat sceneM_R;
    cv::Mat sceneM_G;
    cv::Mat sceneM_B;

    UIImageToMat(image, sceneM);
    [self addItem:image description:@"原圖"];

    cv::cvtColor(sceneM, sceneM_gray, CV_BGR2GRAY);
    //  做通道分離，會拆解成 B G R
    std::vector<cv::Mat> sceneChannels;
    sceneChannels.push_back(cv::Mat());
    sceneChannels.push_back(cv::Mat());
    sceneChannels.push_back(cv::Mat());
    cv::split(sceneM, sceneChannels);
    sceneM_B = sceneChannels[0];
    sceneM_G = sceneChannels[1];
    sceneM_R = sceneChannels[2];
    
    // 計算直方圖
    int histSize = 256; // bin 數
    float range[] = {0,255};  
    const float* ranges={range}; // bin
    cv::Mat sceneM_B_hist;
    cv::Mat sceneM_G_hist;
    cv::Mat sceneM_R_hist;
    
    cv::calcHist(&sceneM_B, 1, 0, cv::Mat(), sceneM_B_hist, 1, &histSize, &ranges,true,false);
    cv::calcHist(&sceneM_G, 1, 0, cv::Mat(), sceneM_G_hist, 1, &histSize, &ranges,true,false);
    cv::calcHist(&sceneM_R, 1, 0, cv::Mat(), sceneM_R_hist, 1, &histSize, &ranges,true,false);
    
    // 準備繪圖
    cv::Mat histImg_B(histSize, histSize, CV_8UC3, cv::Scalar(255,255,255));//把直方圖秀在一個256*256大的影像上
    cv::Mat histImg_G(histSize, histSize, CV_8UC3, cv::Scalar(255,255,255));//把直方圖秀在一個256*256大的影像上
    cv::Mat histImg_R(histSize, histSize, CV_8UC3, cv::Scalar(255,255,255));//把直方圖秀在一個256*256大的影像上
    
    [self drawHistMat:sceneM_B_hist dst:histImg_B histSize:histSize color:cv::Scalar(0,0,255)];
    [self drawHistMat:sceneM_G_hist dst:histImg_G histSize:histSize color:cv::Scalar(0,255,0)];
    [self drawHistMat:sceneM_R_hist dst:histImg_R histSize:histSize color:cv::Scalar(255,0,0)];
    
    [self addItemMat:histImg_B description:@"sceneM_B 直方圖"];
    [self addItemMat:histImg_G description:@"sceneM_G 直方圖"];
    [self addItemMat:histImg_R description:@"sceneM_R 直方圖"];
    
}

- (void)backprojectObj:(UIImage*)imageObj
{
    cv::Mat objM;

    UIImageToMat(imageObj, objM);
    
    cv::cvtColor(objM, objM, CV_BGR2HSV);
    
    cv::Mat hue;
    int bins = 30; // 分30個區間
    hue.create(objM.size(), objM.depth());
    //通道索引对的数组，&hsv图像的Hue(0)通道被拷贝到&hue图像(单通道)的0通道。
    int nchannels[] = { 0, 0 }; 
    //抽取HSV图像的0通道拷贝到hue：输入图像指针，输入图像数，输出图像指针，输出图像数，通道索引对，通道索引对的数目
    mixChannels(&objM, 1, &hue, 1, nchannels, 1); 
    
    /*计算直方图并归一化*/
    float range[] = { 0, 360 }; //H取值范围
    const float *histRanges = { range };
    
    cv::Mat h_hist;
    cv::Mat h_histImg(256, 256, CV_8U, cv::Scalar(255)); // 用一張 256*256 的白色底的圖來顯示
    //计算直方图
    calcHist(&hue, 1, 0, cv::Mat(), h_hist, 1, &bins, &histRanges, true, false);
    [self drawHistMat:h_hist dst:h_histImg histSize:bins color:cv::Scalar(0)];
    [self addItemMat:h_histImg description:@"hue 直方圖"];
    //归一化，把直方圖的值，映射至 0~255 之間
    normalize(h_hist, h_hist, 0, 255, cv::NORM_MINMAX, -1, cv::Mat()); 
    
    /*反向投影*/
    cv::Mat backProjImage;
    //反向投影：输入图像指针，输入图像数量，通道数，直方图，输出，值域，比例尺度
    calcBackProject(&hue, 1, 0, h_hist, backProjImage, &histRanges, 1, true);

    [self addItemMat:objM description:@"scene hsv"];
    [self addItemMat:backProjImage description:@"反向投影"];
}

-(void)drawHistMat:(cv::Mat &)src dst:(cv::Mat &)dst histSize:(int)histSize color:(cv::Scalar)color
{
    float histMax = 0;
    for(int i=0; i<histSize; i++){
        float tempValue = src.at<float>(i);
        if(histMax < tempValue){
            histMax = tempValue;
        }
    }
    int lineWidth = dst.cols / histSize;
    float scale = (0.9*dst.rows)/histMax;
    for(int i=0; i<histSize; i++){
        int intensity = static_cast<int>(src.at<float>(i)*scale);
        cv::line(dst,cv::Point(i*lineWidth,255),cv::Point(i*lineWidth,255-intensity),color,lineWidth);
    }
}

@end
