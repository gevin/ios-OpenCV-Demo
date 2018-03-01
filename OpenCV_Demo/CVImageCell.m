//
//  CVImageCell.m
//  OpenCV_featureMatching_demo
//
//  Created by GevinChen on 2018/2/13.
//  Copyright © 2018年 GevinChen. All rights reserved.
//

#import "CVImageCell.h"

@implementation CVImageCell

- (void)awakeFromNib {
    [super awakeFromNib];
    // Initialization code
}

- (void)onLoad:(CVImageProcessModel*)model
{
    self.image.image = model.image;
    self.labelDescription.text = model.descriptionString;
}

@end

@implementation CVImageProcessModel

@end
