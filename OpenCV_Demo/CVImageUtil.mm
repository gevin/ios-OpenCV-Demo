//
//  CVImageUtil.m
//  OpenCV_featureMatching_demo
//
//  Created by GevinChen on 2018/2/23.
//  Copyright © 2018年 GevinChen. All rights reserved.
//

#import "CVImageUtil.h"

@implementation CVImageUtil


//ratio test nearest/second nearest < ratio
+(std::vector<cv::DMatch>)ratio_testMatches:(std::vector< std::vector<cv::DMatch> >)matches12 ratio:(double)ratio{
    std::vector<cv::DMatch> good_matches;         
    for(int i = 0; i < matches12.size(); i++){  
        if(matches12[i][0].distance < ratio * matches12[i][1].distance)
            good_matches.push_back(matches12[i][0]);
    }
    return good_matches;
}

// Symmetric Test...
+(std::vector<cv::DMatch>)symmetric_testMatch1:(std::vector<cv::DMatch>)good_matches1 match2:(std::vector<cv::DMatch>) good_matches2{
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
+(bool)refineMatchesWithHomographyObjMat:(cv::Mat&)objM
                                sceneMat:(cv::Mat&)sceneM
                            objKeypoints:(std::vector<cv::KeyPoint>)queryKeypoints
                          sceneKeypoints:(std::vector<cv::KeyPoint>)trainKeypoints
                                 matches:(std::vector<cv::DMatch> &)matches
                                  output:(cv::Mat&)outImg
                   ransacReprojThreshold:(double)ransacReprojThreshold
{  
    
    const int minNumberMatchesAllowed = 8;    
    if (matches.size() < minNumberMatchesAllowed)    
        return false;
    
    // Prepare data for cv::findHomography    
    std::vector<cv::Point2f> queryPoints(matches.size());    
    std::vector<cv::Point2f> trainPoints(matches.size());    
    for (size_t i = 0; i < matches.size(); i++){
        queryPoints[i] = queryKeypoints[matches[i].queryIdx].pt;    
        trainPoints[i] = trainKeypoints[matches[i].trainIdx].pt;    
    }
    // Find homography matrix and get inliers mask    
    std::vector<unsigned char> inliersMask(matches.size());    
    
    // homography 會是一個 3*3 矩陣，用來做平面座標轉換
    cv::Mat homography;
    homography = cv::findHomography(queryPoints,
                                    trainPoints,
                                    CV_FM_RANSAC,
                                    ransacReprojThreshold,
                                    inliersMask);
    std::vector<cv::DMatch> inliers;  
    for (size_t i=0; i<inliersMask.size(); i++)  {  
        if (inliersMask[i])  
            inliers.push_back(matches[i]);  
    }  
    matches.swap(inliers); 
    
    std::vector<cv::Point2f> srcCorner(4);  
    std::vector<cv::Point2f> dstCorner(4);
    int width = objM.cols;
    int height = objM.rows;
    srcCorner[0] = cv::Point(0,0);  
    srcCorner[1] = cv::Point(width,0);  
    srcCorner[2] = cv::Point(width,height);  
    srcCorner[3] = cv::Point(0,height);
    // 進行矩陣轉換，把 srcCorner 投影到 dstCorner
    
    cv::perspectiveTransform( srcCorner, dstCorner, homography);
    
    int lineWidth = 5;
    cv::Scalar color = cv::Scalar(255,0,0,255);
    outImg = sceneM.clone();
    cv::line(outImg,dstCorner[0],dstCorner[1],color,lineWidth);  
    cv::line(outImg,dstCorner[1],dstCorner[2],color,lineWidth);  
    cv::line(outImg,dstCorner[2],dstCorner[3],color,lineWidth);  
    cv::line(outImg,dstCorner[3],dstCorner[0],color,lineWidth);  
    return true;  
}


+(void)findContoursSrcGray:(cv::Mat&)src_gray dst:(cv::Mat&)dst
{
    // 找輪廓
    std::vector<std::vector<cv::Point> > contours;  
    std::vector<cv::Vec4i> hierarchy; 
    cv::findContours(src_gray, contours, hierarchy, CV_RETR_LIST, CV_CHAIN_APPROX_NONE);
    //将contours结果放入到markers中，便于访问  
    int idx = 0;  
    for( ; idx >= 0; idx = hierarchy[idx][0]){  
        cv::Scalar color(rand()&255, rand()&255, rand()&255);  
        drawContours(dst, contours, idx, color, CV_FILLED, 8, hierarchy);  
    }
}

+(void)waterSegmentSrc:(cv::Mat&)src dst:(cv::Mat&)dst
{
    cv::Mat src_gray;
    cv::cvtColor(src, src_gray, CV_BGR2GRAY);
    
    // 分水嶺算法
    cv::Mat markers = cv::Mat::zeros(src_gray.rows, src_gray.cols, CV_8U);
    int blockSize = MIN(src.cols,src.rows) / 10;
    if (blockSize%2 == 0 ) {
        blockSize++;
    }
    // 先做 區域二值化
    cv::adaptiveThreshold(src_gray, src_gray, 255, cv::ADAPTIVE_THRESH_GAUSSIAN_C, cv::THRESH_BINARY_INV, blockSize, 10);
    
//    if(debug) [self addItemMat:src_gray description:@"scene 分水嶺算法-二值化"];
    // 找輪廓
    std::vector<std::vector<cv::Point> > contours;  
    std::vector<cv::Vec4i> hierarchy; 
    cv::findContours(src_gray, contours, hierarchy, CV_RETR_LIST, CV_CHAIN_APPROX_NONE);
    //将contours结果放入到markers中，便于访问  
    int idx = 0;  
    for( ; idx >= 0; idx = hierarchy[idx][0]){  
        cv::Scalar color(rand()&255, rand()&255, rand()&255);  
        drawContours(markers, contours, idx, color, CV_FILLED, 8, hierarchy);  
    }
//    if(debug) [self addItemMat:markers description:@"scene 分水嶺算法-找輪廓"];
    
    cv::Mat sceneMat_watershed;
    markers.convertTo(markers, CV_32S);
    // 8uc4 convert to 8uc3
    if(src.channels()==4){
        cv::cvtColor(src, sceneMat_watershed, CV_BGRA2BGR);
    }
    else{
        sceneMat_watershed = src;
    }
    cv::watershed(sceneMat_watershed, markers);
    markers.convertTo(dst, CV_8U);
//    if(debug) [self addItemMat:markers description:@"scene 分水嶺算法-結果"];
    
}

+(void)resizeMat:(cv::Mat&)src bound:(float)bound
{
    [self resizeMat:src dst:src bound:bound];
}

+(void)resizeMat:(cv::Mat&)src dst:(cv::Mat&)dst bound:(float)bound
{
    if(src.cols > bound){
        cv::Size size = cv::Size(bound, (int)(src.rows * (bound/src.cols)) );
        cv::resize(src, dst, size);
    }
    else if(src.rows > bound ){
        cv::Size size = cv::Size( (int)(src.cols * (bound/src.rows)), bound );
        cv::resize(src, dst, size);
    }
}

#pragma mark - Draw


// 畫出匹配的點
+(void)drawMatchKeypoint:(cv::Mat&)sceneM keypoints:(std::vector<cv::KeyPoint>)keypoints matches:(std::vector<cv::DMatch>)matches
{
    cv::Scalar color = cv::Scalar(255,0,0); // RGB
    std::for_each(matches.begin(), matches.end(), [&](cv::DMatch match){
        cv::KeyPoint keypoint = keypoints[match.queryIdx];
        cv::circle(sceneM, keypoint.pt, 5, color);
    });
}

// 畫出匹配的點
+(void)drawLineMatchKeypoint:(cv::Mat&)sceneM keypoints:(std::vector<cv::KeyPoint>)keypoints matches:(std::vector<cv::DMatch>)matches
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

+(void)drawPointMat:(cv::Mat&)dst_m points:(std::vector<cv::Point>)points
{
    cv::Scalar color = cv::Scalar(255,255,0); // RGB
    int cnt = points.size();
    for(int i = 0; i<cnt; i++)
    {
        //cv::line(dst_m, points[i], points[(i+1)%cnt], color);
        cv::circle(dst_m, points[i], 5, color);
    }    
}

+(void)drawLine:(cv::Mat&)dst_m keypoints:(std::vector<cv::Point>)points
{
    
    cv::Scalar color = cv::Scalar(255,0,0,255); // RGB
    int cnt = points.size();
    for(int i = 0; i<cnt; i++){
        cv::line(dst_m, points[i], points[(i+1)%cnt], color);
    }    
}

#pragma mark - Convert

+(UIImage *)fixrotation:(UIImage *)image
{
    
    if (image.imageOrientation == UIImageOrientationUp) return image;
    CGAffineTransform transform = CGAffineTransformIdentity;
    
    switch (image.imageOrientation) {
        case UIImageOrientationDown:
        case UIImageOrientationDownMirrored:
            transform = CGAffineTransformTranslate(transform, image.size.width, image.size.height);
            transform = CGAffineTransformRotate(transform, M_PI);
            break;
            
        case UIImageOrientationLeft:
        case UIImageOrientationLeftMirrored:
            transform = CGAffineTransformTranslate(transform, image.size.width, 0);
            transform = CGAffineTransformRotate(transform, M_PI_2);
            break;
            
        case UIImageOrientationRight:
        case UIImageOrientationRightMirrored:
            transform = CGAffineTransformTranslate(transform, 0, image.size.height);
            transform = CGAffineTransformRotate(transform, -M_PI_2);
            break;
        case UIImageOrientationUp:
        case UIImageOrientationUpMirrored:
            break;
    }
    
    switch (image.imageOrientation) {
        case UIImageOrientationUpMirrored:
        case UIImageOrientationDownMirrored:
            transform = CGAffineTransformTranslate(transform, image.size.width, 0);
            transform = CGAffineTransformScale(transform, -1, 1);
            break;
            
        case UIImageOrientationLeftMirrored:
        case UIImageOrientationRightMirrored:
            transform = CGAffineTransformTranslate(transform, image.size.height, 0);
            transform = CGAffineTransformScale(transform, -1, 1);
            break;
        case UIImageOrientationUp:
        case UIImageOrientationDown:
        case UIImageOrientationLeft:
        case UIImageOrientationRight:
            break;
    }
    
    // Now we draw the underlying CGImage into a new context, applying the transform
    // calculated above.
    CGContextRef ctx = CGBitmapContextCreate(NULL, image.size.width, image.size.height,
                                             CGImageGetBitsPerComponent(image.CGImage), 0,
                                             CGImageGetColorSpace(image.CGImage),
                                             CGImageGetBitmapInfo(image.CGImage));
    CGContextConcatCTM(ctx, transform);
    switch (image.imageOrientation) {
        case UIImageOrientationLeft:
        case UIImageOrientationLeftMirrored:
        case UIImageOrientationRight:
        case UIImageOrientationRightMirrored:
            // Grr...
            CGContextDrawImage(ctx, CGRectMake(0,0,image.size.height,image.size.width), image.CGImage);
            break;
            
        default:
            CGContextDrawImage(ctx, CGRectMake(0,0,image.size.width,image.size.height), image.CGImage);
            break;
    }
    
    // And now we just create a new UIImage from the drawing context
    CGImageRef cgimg = CGBitmapContextCreateImage(ctx);
    UIImage *img = [UIImage imageWithCGImage:cgimg];
    CGContextRelease(ctx);
    CGImageRelease(cgimg);
    return img;
}

@end
