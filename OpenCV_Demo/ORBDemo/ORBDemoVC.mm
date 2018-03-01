//
//  ORBDemoVC.m
//  OpenCV_featureMatching_demo
//
//  Created by GevinChen on 2018/2/12.
//  Copyright © 2018年 GevinChen. All rights reserved.
//

#import "ORBDemoVC.h"
#import "CVImageCell.h"
#import "CVImageUtil.h"

@interface ORBDemoVC ()<UICollectionViewDelegate,UICollectionViewDataSource, UIImagePickerControllerDelegate, UINavigationControllerDelegate>
{
    UIImage *_objectImage;
    
    NSMutableArray *_itemsList;
    
    cv::Ptr<cv::FeatureDetector> detector;
    cv::Ptr<cv::DescriptorExtractor> extractor;
    cv::Ptr<cv::DescriptorMatcher> matcher;
//    cv::FlannBasedMatcher matcher;
    
    BOOL _firstLoad;
}

@property (weak, nonatomic) IBOutlet UIButton *btnStart;

@end

@implementation ORBDemoVC

- (void)viewDidLoad {
    [super viewDidLoad];

    self.btnStart.layer.cornerRadius = 5;
    self.btnStart.layer.borderColor = [UIColor blueColor].CGColor;
    self.btnStart.layer.borderWidth = 1;

    _objectImage = [UIImage imageNamed:@"wallet2.png"];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    if(!_firstLoad){
        _firstLoad = YES;
        [self featureMatchingObj:_objectImage sceneImg:[UIImage imageNamed:@"wallet_scene2.png"]];
    }
}

- (IBAction)btnClicked:(id)sender {
    
    typeof(self) w_self = self;
    [self removeAllItem];
    [self takePhoto:^(UIImage *image) {
        [w_self featureMatchingObj:_objectImage sceneImg:image];
    }];
    
}

- (IBAction)btnBackClicked:(id)sender {
    
    [self dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - OpenCV 


/*
 特徵比對的步驟
 1. 關鍵點搜尋，用 feature detector 找出特徵關鍵點 (key points)
 2. 特徵抽取，用 feature descriptor 取出特徵 local feature 
 3. 再用 local feature 對兩張圖做 feature matching，DescriptorMatcher
 */

/*
 特徵點 class
 class KeyPoint
 {     
     Point2f  pt;  //坐标
     float  size; //特征点邻域直径
     float  angle; //特征点的方向，值为[零,三百六十)，负值表示不使用
     float  response;
     int  octave; //特征点所在的图像金字塔的组
     int  class_id; //用于聚类的id    
 }
 
 CV_WRAP是用來包裝函數或方法的一個標記，主要為了Python和Java的接口封裝。
 
 存放比對結果的結構:
 struct DMatch
 {   // 三個建構函數
     DMatch(): 
     queryIdx(-1),trainIdx(-1),imgIdx(-1),distance(std::numeric_limits<float>::max()) {}
     DMatch(int _queryIdx, int _trainIdx, float _distance ): 
     queryIdx( _queryIdx),trainIdx( _trainIdx), imgIdx(-1),distance( _distance) {}
     DMatch(int _queryIdx, int _trainIdx, int _imgIdx, float _distance ): 
     queryIdx(_queryIdx), trainIdx( _trainIdx), imgIdx( _imgIdx),distance( _distance) {}
     int queryIdx;  // 特徵點陣列裡的索引
     int trainIdx;  // 特徵點陣列裡的索引
     int imgIdx;    // 训练图像的索引(若有多个)
     float distance;  //两个特征向量之间的欧氏距离，越小表明匹配度越高。
     bool operator < (const DMatch &m) const;
 };
 
 
 */

/**
 特徵比對

 @param objImg 對於 cv 裡的名詞應該就是 queryImage
 @param sceneImg 對於 cv 裡的名詞應該就是 trainImage
 */
- (void)featureMatchingObj:(UIImage*)objImg sceneImg:(UIImage*)sceneImg
{

    // note: 用不同的特徵搜尋，效果不同，像我測試的 logo 直角很多，用 HARRIS 角點檢測，搜尋結果最好，用 ORB 卻框不出定位區域
    cv::initModule_features2d();
    cv::initModule_nonfree(); // for SIFT SURF
    detector = cv::FeatureDetector::create("ORB"); // FAST , STAR , SIFT , SURF , ORB , BRISK , MSER , GFTT , HARRIS , Dense , SimpleBlob , Grid{xxx} , Pyramid{xxx} ex: GridORB
    extractor = cv::DescriptorExtractor::create("ORB"); // "SIFT" "SURF" "BRIEF" "BRISK" "ORB" "FREAK"
    matcher = cv::DescriptorMatcher::create("BruteForce-Hamming");  // BruteForce (L2), BruteForce-L1, BruteForce-Hamming, BruteForce-Hamming(2), FlannBased
//    matcher = cv::FlannBasedMatcher(new cv::flann::LshIndexParams(20,10,2)); // for orb
    
    std::vector<cv::KeyPoint> keypoints1, keypoints2;
    cv::Mat descriptors1, descriptors2;
    std::vector< std::vector<cv::DMatch> > matches12, matches21;
    
    cv::Mat objM, sceneM;
    cv::Mat objM_gray, sceneM_gray;
    cv::Mat outputM, outputM2;
    UIImageToMat(objImg ,objM);
    UIImageToMat(sceneImg ,sceneM );
    
    // resize
    [CVImageUtil resizeMat:objM bound:1024];
    [CVImageUtil resizeMat:sceneM bound:1024];
    
    //  轉灰階
    cv::cvtColor(objM, objM_gray, CV_BGR2GRAY);
    cv::cvtColor(sceneM, sceneM_gray, CV_BGR2GRAY);
    
    // 加亮
//    objM_gray = objM_gray + cv::Scalar(120);
//    sceneM_gray = sceneM_gray + cv::Scalar(120);
    
    // 等化直方圖
//    cv::equalizeHist(objM_gray, objM_gray);
//    cv::equalizeHist(sceneM_gray, sceneM_gray);
    
    // 模糊
//    cv::blur(objM_gray, objM_gray, cv::Size(3,3));
//    cv::blur(sceneM_gray, sceneM_gray, cv::Size(3,3));

    // 銳化
//    cv::Laplacian(objM_gray, objM_gray,CV_8U,3,1,0, cv::BORDER_DEFAULT);
//    cv::Laplacian(sceneM_gray, sceneM_gray,CV_8U,3,1,0, cv::BORDER_DEFAULT);
//    [self addItemMat:objM_gray description:@"obj 銳化"];
//    [self addItemMat:sceneM_gray description:@"scene 銳化"];
    
    // 二值化
//    cv::threshold(objM_gray, objM_gray, 120, 255, cv::THRESH_BINARY_INV);
//    cv::threshold(sceneM_gray, sceneM_gray, 120, 255, cv::THRESH_BINARY_INV);
//    [self addItemMat:objM_gray description:@"obj 二值化"];
//    [self addItemMat:sceneM_gray description:@"scene 二值化"];
    
    // 找輪廓
//    [CVImageUtil findContoursSrcGray:objM_gray dst:objM_gray];
//    [CVImageUtil findContoursSrcGray:sceneM_gray dst:sceneM_gray];
//    [self addItemMat:objM_gray description:@"obj 找輪廓"];
//    [self addItemMat:sceneM_gray description:@"scene 找輪廓"];
    
    // 找邊緣
//    cv::Canny(objM_gray, objM_gray, 120, 255);
//    cv::Canny(sceneM_gray, sceneM_gray, 120, 255);
//    [self addItemMat:objM_gray description:@"obj 找邊緣"];
//    [self addItemMat:sceneM_gray description:@"scene 找邊緣"];
    
    // 區域二值化
//    int blockSize = MIN(objM.cols,objM.rows) / 10;
//    if (blockSize%2 == 0 ) {
//        blockSize++;
//    }
//    cv::adaptiveThreshold(objM_gray, objM_gray, 255, cv::ADAPTIVE_THRESH_GAUSSIAN_C, cv::THRESH_BINARY, blockSize, 10); // 最後一個值似乎是做完二值化後再消去一個量，給值越大，畫面越乾淨
//    int blockSize2 = MIN(objM.cols,objM.rows) / 10;
//    if (blockSize2%2 == 0 ) {
//        blockSize2++;
//    }
//    cv::adaptiveThreshold(sceneM_gray, sceneM_gray, 255, cv::ADAPTIVE_THRESH_GAUSSIAN_C, cv::THRESH_BINARY, blockSize2, 10);
//    [self addItemMat:objM_gray description:@"obj 區域二值化"];
//    [self addItemMat:sceneM_gray description:@"scene 區域二值化"];

//    cv::Mat objM_dilate, sceneM_dilate;
//    cv::Mat objM_erode, sceneM_erode;
    
    // 澎脹
//    cv::dilate(objM_gray,objM_gray,cv::Mat(),cv::Point(-1,-1),1);
//    cv::dilate(sceneM_gray,sceneM_gray,cv::Mat(),cv::Point(-1,-1),1);
//    [self addItemMat:objM_gray description:@"obj 澎脹"];
//    [self addItemMat:sceneM_gray description:@"scene 澎脹"];
    
    // 侵蝕
//    cv::erode(objM_gray,objM_gray,cv::Mat(),cv::Point(-1,-1),2);
//    cv::erode(sceneM_gray,sceneM_gray,cv::Mat(),cv::Point(-1,-1),2);
//    [self addItemMat:objM_gray description:@"obj 侵蝕"];
//    [self addItemMat:sceneM_gray description:@"scene 侵蝕"];
    
    // 形態學梯度
//    cv::Mat element = cv::getStructuringElement(cv::MORPH_RECT, cv::Size(2, 2));
//    cv::morphologyEx(objM_gray, objM_gray, cv::MORPH_GRADIENT, element);
//    cv::morphologyEx(sceneM_gray, sceneM_gray, cv::MORPH_GRADIENT, element);
//    [self addItemMat:objM_gray description:@"obj 形態學梯度"];
//    [self addItemMat:sceneM_gray description:@"scene 形態學梯度"];
    
    // 分水嶺算法
//    [CVImageUtil waterSegmentSrc:objM dst:objM_gray];
//    [CVImageUtil waterSegmentSrc:sceneM dst:sceneM_gray];
//    [self addItemMat:objM_gray description:@"obj 分水嶺算法"];
//    [self addItemMat:sceneM_gray description:@"scene 分水嶺算法"];

    //--------------------------------------
    //  1. detect features
    //--------------------------------------
    detector->detect(objM_gray, keypoints1);
    detector->detect(sceneM_gray, keypoints2);
    
    //--------------------------------------
    //  2. extract the descriptors
    //--------------------------------------
    extractor->compute(objM_gray,keypoints1,descriptors1);
    extractor->compute(sceneM_gray,keypoints2,descriptors2);
    
    //--------------------------------------
    //  3.Match the descriptors in two directions...
    //--------------------------------------
    matcher->knnMatch( descriptors1, descriptors2, matches12, 2 );
//    matcher->knnMatch( descriptors2, descriptors1, matches21, 2 );
    
    //--------------------------------------
    //  4. ratio test proposed by David Lowe paper = 0.8
    //--------------------------------------
    // 逐一比對已配對的 keypoint，距離差異小於0.8 則認定為符合關鍵點
    double ratio = 0.8;
    std::vector<cv::DMatch> good_matches1, good_matches2;
    good_matches1 = [CVImageUtil ratio_testMatches:matches12 ratio:ratio];
//    good_matches2 = [CVImageUtil ratio_testMatches:matches21 ratio:ratio];
    
    //--------------------------------------
    //  畫出 key points
    //--------------------------------------
//    [CVImageUtil drawMatchKeypoint:objM keypoints:keypoints1 matches:good_matches1];
//    [self addItemMat:objM description:@"match keypoint"];
//    [CVImageUtil drawMatchKeypoint:sceneM keypoints:keypoints2 matches:good_matches2];
//    [self addItemMat:sceneM description:@"scene keypoint"];

    //--------------------------------------
    //  畫出 feature match
    //--------------------------------------
    // 預設吃灰階圖，傳彩色圖進去會畫不出來
//    cv::drawMatches(objM_gray, keypoints1, sceneM_gray, keypoints2, good_matches1, outputM, cv::Scalar(255,0,0), cv::Scalar(0,255,0));
//    [self addItemMat:outputM description:@"match"];
    
    //--------------------------------------
    // 5. Symmetric Test
    //--------------------------------------
    // 兩組 match 比對，比較好的 match 是 obj 的 a 點對到 scene 的 a 點
    // 但有時候特徵相似，會造成 obj 的 a 點對到 scene 的 b 點，這種就無效，執行下面的相互比對，就可以把這類無效 match 去除 
//    std::vector<cv::DMatch> better_matches;
//    better_matches = [CVImageUtil symmetric_testMatch1:good_matches1 
//                                                match2:good_matches2];
    
    //--------------------------------------
    //  find obj in scene
    //--------------------------------------
    // 框出匹配的物件，利用 findHomography
    //  note: 若輸入的參數型態不合 function 介面，就會發生  No matching function for call to 的 error
    bool findHomography = [CVImageUtil refineMatchesWithHomographyObjMat: objM
                                                                sceneMat: sceneM
                                                            objKeypoints: keypoints1
                                                          sceneKeypoints: keypoints2
                                                                 matches: good_matches1 
                                                                  output: outputM2
                                                   ransacReprojThreshold: 5];
    //--------------------------------------
    //  畫出 better feature match
    //--------------------------------------
//    cv::Mat betterMatchM;
    cv::drawMatches(objM_gray, keypoints1, sceneM_gray, keypoints2, good_matches1, outputM, cv::Scalar(255,0,0), cv::Scalar(0,255,0));
    [self addItemMat:outputM description:@"better match"];

    if(findHomography){
        [self addItemMat:outputM2 description:@"Homography"];
    }

    //5. Compute the similarity of this image pair...
//    float jaccard = 1.0 * better_matches.size() / (keypoints1.size() + keypoints2.size() - better_matches.size());
    
}


@end
