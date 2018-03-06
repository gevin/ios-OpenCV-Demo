//
//  MeanShiftVC.m
//  OpenCV_Demo
//
//  Created by GevinChen on 2018/2/28.
//  Copyright © 2018年 GevinChen. All rights reserved.
//

#import "MeanShiftVC.h"

@interface MeanShiftVC () < CvVideoCameraDelegate >
{
    CvVideoCamera *camera;
    
    UIImage *_imageObj;
    
    BOOL _initLoad;
    
    cv::Rect track_rect;
    cv::Mat roi_hist;
    cv::Mat track_obj_backProj;
    int track_object;
    
    BOOL _start;
    UIView *_rectView;
}

@property (weak, nonatomic) IBOutlet UIImageView *imageView;
@property (weak, nonatomic) IBOutlet UIButton *btnStart;
@property (weak, nonatomic) IBOutlet UIButton *btnBack;

@end

@implementation MeanShiftVC

- (void)viewDidLoad {
    [super viewDidLoad];
    //Camera
    camera = [[CvVideoCamera alloc] initWithParentView: self.imageView];
    camera.defaultAVCaptureDevicePosition = AVCaptureDevicePositionBack;
    camera.defaultAVCaptureSessionPreset = AVCaptureSessionPreset640x480;
    camera.defaultAVCaptureVideoOrientation = AVCaptureVideoOrientationPortrait;
    camera.defaultFPS = 30;
    camera.grayscaleMode = NO;
    camera.delegate = self;
    
//    _rectView = [[UIView alloc] initWithFrame:(CGRect){0,0,40,40}];
//    _rectView.layer.borderColor = [UIColor redColor].CGColor;
//    _rectView.layer.borderWidth = 4;
    
    [self.imageView addSubview:_rectView];
    
    _imageObj = [UIImage imageNamed:@"wallet_scene.png"];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    if(!_initLoad){
        _initLoad= YES;
        [camera start];
    }
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    [camera stop];
}


#pragma mark - Button Action

- (IBAction)btnStartClicked:(id)sender {
    self.btnStart.selected = !self.btnStart.selected;
    _start = self.btnStart.selected; 
    if(!_start){
        track_object = 0;
        track_rect.width = 0;
        track_rect.height = 0;
    }
}

- (IBAction)btnBackClicked:(id)sender {
    [self dismissViewControllerAnimated:YES completion:nil];
    _start = NO;
}

#pragma mark - Touch

- (void)touchesEnded:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event
{
    UITouch *touch = [touches anyObject];
    CGPoint point = [touch locationInView:self.view];
    
    if(CGRectContainsPoint(self.imageView.frame, point)){
//        _rectView.center = point;
//        [self.imageView bringSubviewToFront:_rectView];

        //  把點映射到 480*640 的座標內
        CGSize display_size = self.imageView.bounds.size;
        point = CGPointMake( point.x *(480.0/display_size.width), point.y *(640.0/display_size.height) );
        
        float w = 40;
        float h = 40;
        track_rect = cv::Rect( (int)(point.x - w/2), (int)(point.y - h/2), (int)w, (int)h);
        track_object = 0;
//        NSLog(@"touch %@", NSStringFromCGPoint(point));
    }
}

#pragma mark - Camera Raw Data

-(void)processImage:(cv::Mat &)image
{
    if(!_start)
        return;
    
    if(track_rect.width == 0 || track_rect.height == 0 )
        return;
    
    // hsv 通道分離，只取出 hue
//    cv::Mat hue;
//    hue.create(image.size(), image.depth());
//    // 通道索引，cv::Mat image 的 channel 0 (hue)，複製到 cv::Mat hue (單通道)的 channel 0
//    int nchannels[] = { 0, 0 }; 
//    // 抽取HSV圖像的0通道，複製到到hue的0通道
//    mixChannels(&image,     // 輸入圖像
//                1,          // 輸入圖像數量
//                &hue,       // 輸出圖像
//                1,          // 輸出圖像數量
//                nchannels,  // 複製通道的索引
//                1);         // 表製通道的數量
    
    int bins[] = {60}; // 分60個區間
    float range[] = { 0, 180 }; //H取值的範圍
    const float *histRanges = { range };
    int channels[] = { 0,1,2 };
    //int ch = 0;
    if( track_object == 0 ){
        // 取出畫面要追蹤的區域
        cv::Mat roi = image(track_rect);
        cv::Mat roi_hsv;
        // 轉成 hsv
        cv::cvtColor(roi, roi_hsv, CV_BGR2HSV);
        
        // 設定 hsv 遮罩, h= 0~180, s=60~255, v=32~255
        cv::Mat roi_mask;
        cv::inRange(roi_hsv, cv::Scalar(0.0, 60.0, 32.0), cv::Scalar(180.0, 255.0, 255.0),roi_mask);
        
        // 計算直方圖 & 歸一化
        calcHist(&roi_hsv, 1, channels, roi_mask, roi_hist, 1, bins, &histRanges, true, false);
        normalize(roi_hist, roi_hist, 0,255, CV_MINMAX);
        
        track_object = 1;
        printf("> !!! calc roi hist !!!\n");
    }
    else{
        cv::Mat srcM;
        cv::cvtColor(image, srcM, CV_BGR2HSV);
        
        calcBackProject( &srcM, 1, channels, roi_hist, track_obj_backProj, &histRanges, 1, true );
        
        cv::TermCriteria criteria(cv::TermCriteria::MAX_ITER | cv::TermCriteria::EPS, 10, 0.01);
        cv::meanShift(track_obj_backProj, track_rect, criteria);
        printf("> track_rect: %d, %d, %d, %d\n", track_rect.x, track_rect.y, track_rect.width, track_rect.height);
        cv::rectangle(image, track_rect, cv::Scalar(255,128,128));
    }

}


@end
