//
//  CVImageUtil.h
//  OpenCV_featureMatching_demo
//
//  Created by GevinChen on 2018/2/23.
//  Copyright © 2018年 GevinChen. All rights reserved.
//

#ifdef __cplusplus
#import<opencv2/opencv.hpp>
#import<opencv2/core/core_c.h>
#endif

#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>

@interface CVImageUtil : NSObject

#ifdef __cplusplus
//ratio test nearest/second nearest < ratio
+(std::vector<cv::DMatch>)ratio_testMatches:(std::vector< std::vector<cv::DMatch> >)matches12 ratio:(double)ratio;

// Symmetric Test...
+(std::vector<cv::DMatch>)symmetric_testMatch1:(std::vector<cv::DMatch>)good_matches1 match2:(std::vector<cv::DMatch>) good_matches2;

+(bool)refineMatchesWithHomographyObjMat:(cv::Mat&)objM
                                sceneMat:(cv::Mat&)sceneM
                            objKeypoints:(std::vector<cv::KeyPoint>)queryKeypoints
                          sceneKeypoints:(std::vector<cv::KeyPoint>)trainKeypoints
                                 matches:(std::vector<cv::DMatch> &)matches
                                  output:(cv::Mat&)outImg
                   ransacReprojThreshold:(double)ransacReprojThreshold;

+(void)findContoursSrcGray:(cv::Mat&)src_gray dst:(cv::Mat&)dst;

+(void)waterSegmentSrc:(cv::Mat&)src dst:(cv::Mat&)dst;

+(void)resizeMat:(cv::Mat&)src bound:(float)bound;
+(void)resizeMat:(cv::Mat&)src dst:(cv::Mat&)dst bound:(float)bound;

// 畫出匹配的點
+(void)drawMatchKeypoint:(cv::Mat&)sceneM 
                keypoints:(std::vector<cv::KeyPoint>)keypoints 
                  matches:(std::vector<cv::DMatch>)matches;

// 畫出匹配的點
+(void)drawLineMatchKeypoint:(cv::Mat&)sceneM 
                    keypoints:(std::vector<cv::KeyPoint>)keypoints
                      matches:(std::vector<cv::DMatch>)matches;

// 畫點
+(void)drawPointMat:(cv::Mat&)dst_m points:(std::vector<cv::Point>)points;

// 畫線
+(void)drawLine:(cv::Mat&)dst_m keypoints:(std::vector<cv::Point>)points;

// mat 轉成 UIImage
//+(UIImage*)MattoUIImage:(cv::Mat&)m;

// UIImage 轉成 mat
//+(void)UIImagetoMat:(UIImage*)image mat:(cv::Mat&)m;
#endif

// 修正 UIImage 的 orientation
+(UIImage *)fixrotation:(UIImage *)image;


@end
