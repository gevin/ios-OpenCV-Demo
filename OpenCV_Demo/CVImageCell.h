//
//  CVImageCell.h
//  OpenCV_featureMatching_demo
//
//  Created by GevinChen on 2018/2/13.
//  Copyright © 2018年 GevinChen. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface CVImageProcessModel : NSObject

@property (nonatomic,copy) UIImage *image;
@property (nonatomic,copy) NSString *descriptionString;

@end

@interface CVImageCell : UICollectionViewCell
@property (weak, nonatomic) IBOutlet UIImageView *image;
@property (weak, nonatomic) IBOutlet UILabel *labelDescription;

- (void)onLoad:(CVImageProcessModel*)model;

@end
