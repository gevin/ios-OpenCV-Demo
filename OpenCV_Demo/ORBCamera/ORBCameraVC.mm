//
//  ORBCameraVC.m
//  OpenCV_featureMatching_demo
//
//  Created by GevinChen on 2018/2/12.
//  Copyright © 2018年 GevinChen. All rights reserved.
//

#import "ORBCameraVC.h"

@interface ORBCameraVC () < CvVideoCameraDelegate >
{
    CvVideoCamera *camera;
    
    cv::Ptr<cv::FeatureDetector> detector;
    cv::Ptr<cv::DescriptorExtractor> extractor;
    cv::Ptr<cv::DescriptorMatcher> matcher;
    //    cv::FlannBasedMatcher matcher;
    UIImage *objectImage;
    cv::Mat objM;
    cv::Mat objM_gray;
    std::vector<cv::KeyPoint> obj_keypoints;
    cv::Mat obj_descriptors;
    
    BOOL _start;
}
@property (weak, nonatomic) IBOutlet UIImageView *imageView;
@property (weak, nonatomic) IBOutlet UIButton *btnStart;

@end

@implementation ORBCameraVC

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
    
    objectImage = [UIImage imageNamed:@"book1.jpg"];
    
    [self initMatch];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    [camera start];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    [camera stop];
    self.btnStart.selected = NO;
}

#pragma mark - Button Action

- (IBAction)btnStartClicked:(id)sender {
    self.btnStart.selected = !self.btnStart.selected;
    _start = self.btnStart.selected; 
}

- (IBAction)btnBackClicked:(id)sender {
    
    [self dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - Feature Match

- (void)initMatch
{
    //    cv::OrbFeatureDetector();
    // note: 用不同的特徵搜尋，效果不同，像我測試的 logo 直角很多，用 HARRIS 角點檢測，搜尋結果最好，用 ORB 也行但最後卻框不出定位區域
    //
    cv::initModule_features2d();
    detector = cv::FeatureDetector::create("ORB"); // FAST , STAR , SIFT , SURF , ORB , BRISK , MSER , GFTT , HARRIS , Dense , SimpleBlob , Grid{xxx} , Pyramid{xxx} ex: GridORB
    extractor = cv::DescriptorExtractor::create("ORB"); // "SIFT" "SURF" "BRIEF" "BRISK" "ORB" "FREAK"
    matcher = cv::DescriptorMatcher::create("BruteForce-Hamming");  // BruteForce (L2), BruteForce-L1, BruteForce-Hamming, BruteForce-Hamming(2), FlannBased
    //    matcher = cv::FlannBasedMatcher(new cv::flann::LshIndexParams(20,10,2));

    UIImageToMat(objectImage ,objM );
    
    //  轉灰階
    cv::cvtColor(objM, objM_gray, CV_BGR2GRAY);
    //--------------------------------------
    //  1. detect features
    //--------------------------------------
    detector->detect(objM_gray, obj_keypoints);
    
    //--------------------------------------
    //  2. extract the descriptors
    //--------------------------------------
    extractor->compute(objM_gray,obj_keypoints,obj_descriptors);
}



#pragma mark - Camera Raw Data

-(void)processImage:(cv::Mat &)image
{ 
    if (!_start) return;
    
    cv::Mat sceneM = image;
    cv::Mat sceneM_gray;
    cv::cvtColor(sceneM, sceneM_gray, CV_BGR2GRAY);

    std::vector<cv::KeyPoint> scene_keypoints;
    cv::Mat scene_descriptors;
    std::vector< std::vector<cv::DMatch> > matches12, matches21;
    
    //--------------------------------------
    //  1. detect features
    //--------------------------------------
    detector->detect(sceneM_gray, scene_keypoints);
    
    //--------------------------------------
    //  2. extract the descriptors
    //--------------------------------------
    extractor->compute(sceneM_gray,scene_keypoints,scene_descriptors);
    
    //--------------------------------------
    //  3.Match the descriptors in two directions...
    //--------------------------------------
    matcher->knnMatch( obj_descriptors, scene_descriptors, matches12, 2 );
    if(matches12.size() == 0) 
        return;
    
    //--------------------------------------
    //  4. ratio test proposed by David Lowe paper = 0.8
    //--------------------------------------
    // 逐一比對已配對的 keypoint，距離差異小於0.8 則認定為符合關鍵點
    double ratio = 0.8;
    std::vector<cv::DMatch> good_matches1;
    good_matches1 = [self ratio_test:matches12 ratio:ratio];
    if(good_matches1.size() == 0) 
        return;
    
    //--------------------------------------
    //  find obj in scene
    //--------------------------------------
    // 框出匹配的物件，利用 findHomography
    //  note: 若輸入的參數型態不合 function 介面，就會發生  No matching function for call to 的 error
    bool findHomography = [self refineMatchesWithHomographySrc:objM
                                                  objKeypoints:obj_keypoints 
                                                sceneKeypoints:scene_keypoints 
                                                       matches:good_matches1
                                                        output:image];
    
    cv::rectangle(image, cv::Rect(0, 0, image.cols, image.rows), cv::Scalar(255,0,0), 3);
}


#pragma mark - OpenCV func

//ratio test nearest/second nearest < ratio
-(std::vector<cv::DMatch>)ratio_test:(std::vector< std::vector<cv::DMatch> >)matches12 ratio:(double)ratio{
    std::vector<cv::DMatch> good_matches;         
    for(int i = 0; i < matches12.size(); i++){  
        if(matches12[i][0].distance < ratio * matches12[i][1].distance)
            good_matches.push_back(matches12[i][0]);
    }
    return good_matches;                  
}

// Symmetric Test...
-(std::vector<cv::DMatch>)symmetric_testMatch1:(std::vector<cv::DMatch>)good_matches1 match2:(std::vector<cv::DMatch>) good_matches2{
    std::vector<cv::DMatch> better_matches;
    for(int i=0; i<good_matches1.size(); i++){
        for(int j=0; j<good_matches2.size(); j++){
            if(good_matches1[i].queryIdx == good_matches2[j].trainIdx && good_matches2[j].queryIdx == good_matches1[i].trainIdx){
                better_matches.push_back(cv::DMatch(good_matches1[i].queryIdx, good_matches1[i].trainIdx, good_matches1[i].distance));
                break;
            }
        }
    }
    
    return better_matches;
}

// 經測試，若matches 的數量太少，算出來的投影矩陣也不會正確
-(bool)refineMatchesWithHomographySrc:(cv::Mat&)src 
                         objKeypoints:(std::vector<cv::KeyPoint>)queryKeypoints
                       sceneKeypoints:(std::vector<cv::KeyPoint>)trainKeypoints
                              matches:(std::vector<cv::DMatch> &)matches
                               output:(cv::Mat&)outImg  
{  
    
    const int minNumberMatchesAllowed = 10;    
    if (matches.size() < minNumberMatchesAllowed)    
        return false;
    
    // Prepare data for cv::findHomography    
    std::vector<cv::Point2f> queryPoints(matches.size());    
    std::vector<cv::Point2f> trainPoints(matches.size());    
    for (size_t i = 0; i < matches.size(); i++)
    {
        queryPoints[i] = queryKeypoints[matches[i].queryIdx].pt;    
        trainPoints[i] = trainKeypoints[matches[i].trainIdx].pt;    
    }    
    // Find homography matrix and get inliers mask    
//    std::vector<unsigned char> inliersMask(matches.size());    
    
    // homography 會是一個 3*3 矩陣，用來做平面座標轉換
    cv::Mat homography;
    homography = cv::findHomography(queryPoints,
                                    trainPoints,
                                    CV_FM_RANSAC,
                                    5.0 ); /*,
                                    inliersMask);*/
    
    
//    std::vector<cv::DMatch> inliers;  
//    for (size_t i=0; i<inliersMask.size(); i++)  
//    {  
//        if (inliersMask[i])  
//            inliers.push_back(matches[i]);  
//    }  
//    matches.swap(inliers); 
    
    //    queryPoints.clear();
    //    trainPoints.clear();
    //    for (size_t i = 0; i < matches.size(); i++)
    //    {
    //        queryPoints.push_back( queryKeypoints[matches[i].queryIdx].pt );    
    //        trainPoints.push_back( trainKeypoints[matches[i].trainIdx].pt );    
    //    }  
//    for( int i=0; i<3 ; i++){
//        for (int j=0; j<3; j++) {
//            printf("%d , ",homography.at<uchar>(i,j));
//        }
//        printf("\n");
//    }
    
    std::vector<cv::Point2f> srcCorner(4);  
    std::vector<cv::Point2f> dstCorner(4);
    int width = src.cols;
    int height = src.rows;
    srcCorner[0] = cv::Point(0,0);  
    srcCorner[1] = cv::Point(width,0);  
    srcCorner[2] = cv::Point(width,height);  
    srcCorner[3] = cv::Point(0,height);
    // 進行矩陣轉換，把 srcCorner 投影到 dstCorner
    
    cv::perspectiveTransform( srcCorner, dstCorner, homography);
    
    int lineWidth = 5;
    cv::Scalar color = cv::Scalar(255,0,0,255);
    cv::line(outImg,dstCorner[0],dstCorner[1],color,lineWidth);  
    cv::line(outImg,dstCorner[1],dstCorner[2],color,lineWidth);  
    cv::line(outImg,dstCorner[2],dstCorner[3],color,lineWidth);  
    cv::line(outImg,dstCorner[3],dstCorner[0],color,lineWidth);  
    return true;  
}



#pragma mark - Draw


// 畫出匹配的點
- (void)drawMatchKeypoint:(cv::Mat&)sceneM keypoints:(std::vector<cv::KeyPoint>)keypoints matches:(std::vector<cv::DMatch>)matches
{
    cv::Scalar color = cv::Scalar(255,0,0); // RGB
    std::for_each(matches.begin(), matches.end(), [&](cv::DMatch match){
        cv::KeyPoint keypoint = keypoints[match.queryIdx];
        cv::circle(sceneM, keypoint.pt, keypoint.size, color);
    });
}

// 畫出匹配的點
- (void)drawLineMatchKeypoint:(cv::Mat&)sceneM keypoints:(std::vector<cv::KeyPoint>)keypoints matches:(std::vector<cv::DMatch>)matches
{
    cv::Scalar color = cv::Scalar(255,0,0); // RGB
    int cnt = matches.size();
    for(int i = 0; i<cnt; i++)
    {
        cv::DMatch match1 = matches[i];
        cv::DMatch match2 = matches[(i+1)%cnt];
        cv::KeyPoint keypoint1 = keypoints[match1.queryIdx];
        cv::KeyPoint keypoint2 = keypoints[match2.queryIdx];
        cv::line(sceneM, keypoint1.pt, keypoint2.pt, color);
    }    
}

- (void)drawMser:(cv::Mat&)dst_m mserVector:(std::vector<cv::Point>)points
{
    cv::Scalar color = cv::Scalar(255,255,0); // RGB
    int cnt = points.size();
    for(int i = 0; i<cnt; i++)
    {
        //cv::line(dst_m, points[i], points[(i+1)%cnt], color);
        cv::circle(dst_m, points[i], 5, color);
    }    
}

- (void)drawLine:(cv::Mat&)dst_m keypoints:(std::vector<cv::Point>)points
{
    
    cv::Scalar color = cv::Scalar(255,0,0,255); // RGB
    int cnt = points.size();
    for(int i = 0; i<cnt; i++){
        cv::line(dst_m, points[i], points[(i+1)%cnt], color);
    }    
}







@end
