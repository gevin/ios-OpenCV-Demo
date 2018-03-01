//
//  HaarCascadesVC.m
//  OpenCV_Demo
//
//  Created by GevinChen on 2018/2/24.
//  Copyright © 2018年 GevinChen. All rights reserved.
//

#import "HaarCascadesVC.h"

@interface HaarCascadesVC ()
{
    UIImage *_detected_image;
    
    BOOL _firstLoad;
}


@end

@implementation HaarCascadesVC

- (void)viewDidLoad {
    [super viewDidLoad];
    _detected_image = [UIImage imageNamed:@"photos.png"];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    if(!_firstLoad){
        _firstLoad = YES;
        [self haarCascade];
    }
    
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}
- (IBAction)btnTakePhotoClicked:(id)sender {
    [self removeAllItem];
    typeof(self) w_self = self;
    [self takePhoto:^(UIImage *image) {
        _detected_image = image;
        [w_self haarCascade];
    }];
}

- (IBAction)btnBackClicked:(id)sender {
    [self dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - Haar Cascade

- (void)loadFaceData:(NSString*)xmlName classifier:(cv::CascadeClassifier&)cascade
{
    NSString *path = [[NSBundle mainBundle] pathForResource:xmlName ofType:@"xml"];
    cascade.load([path UTF8String]);
}

- (void)haarCascade
{
    cv::Mat srcM;
    UIImageToMat(_detected_image, srcM);
    [self addItemMat:srcM description:@"origin"];
    
    cv::CascadeClassifier face_cascade;
    
    [self loadFaceData:@"haarcascade_profileface" classifier:face_cascade];
//    [self loadFaceData:@"haarcascade_frontalface_default" classifier:face_cascade];
//    [self loadFaceData:@"haarcascade_profileface" classifier:face_cascade];
//    [self loadFaceData:@"haarcascade_profileface" classifier:face_cascade];
    
    // Detect faces
    std::vector<cv::Rect> faces;
    face_cascade.detectMultiScale( srcM, faces, 1.1, 2, 0|CV_HAAR_SCALE_IMAGE, cv::Size(80, 80) );
    
    // Draw circles on the detected faces
    for( int i = 0; i < faces.size(); i++ ){
        cv::Point center( faces[i].x + faces[i].width*0.5, faces[i].y + faces[i].height*0.5 );
        ellipse( srcM, center, cv::Size( faces[i].width*0.5, faces[i].height*0.5), 0, 0, 360, cv::Scalar( 255, 0, 255 ), 4, 8, 0 );
//        NSLog(@"Detecting");
    }
    
    [self addItemMat:srcM description:@"show faces"];
    
}





@end
