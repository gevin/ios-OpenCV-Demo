//
//  CVStepCollectionVC.h
//  OpenCV_Demo
//
//  Created by GevinChen on 2018/2/23.
//  Copyright © 2018年 GevinChen. All rights reserved.
//

#import <UIKit/UIKit.h>

#ifdef __cplusplus
#import<opencv2/opencv.hpp>
#import<opencv2/core/core_c.h>
#import <opencv2/highgui/ios.h>
#endif

#import "CVImageCell.h"
#import "CVImageUtil.h"

@interface CVStepCollectionVC : UIViewController <UICollectionViewDelegate,UICollectionViewDataSource,UIImagePickerControllerDelegate, UINavigationControllerDelegate>

@property (weak, nonatomic) IBOutlet UICollectionView *collectionView;

#ifdef __cplusplus
- (void)addItemPoints:(cv::Point2f*)points size:(int)size refMat:(cv::Mat&)mat descriptString:(NSString*)descString;
- (void)addItemVector:(std::vector<cv::Point>)points refMat:(cv::Mat&)mat descriptString:(NSString*)descString;
- (void)addItemMat:(cv::Mat &)mat description:(NSString*)description;
#endif

- (void)addItem:(UIImage*)image description:(NSString*)description;
- (void)addItem:(CVImageProcessModel*)model;
- (void)removeAllItem;

- (void)takePhoto:(void(^)(UIImage *image))completed;

@end
