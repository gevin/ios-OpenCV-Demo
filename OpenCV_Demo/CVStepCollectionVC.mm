//
//  CVStepCollectionVC.m
//  OpenCV_Demo
//
//  Created by GevinChen on 2018/2/23.
//  Copyright © 2018年 GevinChen. All rights reserved.
//

#import "CVStepCollectionVC.h"

@interface CVStepCollectionVC ()
{
    NSMutableArray *_itemsList;
    UIImagePickerController *imagePicker;
    void(^_takePhotoCompleted)(UIImage *image);
}

@end

@implementation CVStepCollectionVC

- (void)viewDidLoad {
    [super viewDidLoad];
    
    
    self.collectionView.dataSource = self;
    self.collectionView.delegate = self;
    UINib *nib = [UINib nibWithNibName:@"CVImageCell" bundle:[NSBundle mainBundle]];
    NSArray *views = [nib instantiateWithOwner:nil options:nil];
    CVImageCell *prototype = views[0];
    [self.collectionView registerNib:nib forCellWithReuseIdentifier:@"CVImageCell"];
    
    CGSize screenSize = [UIScreen mainScreen].bounds.size;
    UICollectionViewFlowLayout *layout = self.collectionView.collectionViewLayout;
    layout.itemSize = (CGSize){ screenSize.width - 16, prototype.bounds.size.height * (prototype.bounds.size.width/screenSize.width)};
    
    _itemsList = [NSMutableArray new];

    imagePicker = [[UIImagePickerController alloc]init];
    imagePicker.delegate = self;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - UIImagePickerControllerDelegate

- (void)takePhoto:(void(^)(UIImage *image))completed
{
    _takePhotoCompleted = completed;
    imagePicker.sourceType = UIImagePickerControllerSourceTypeCamera;
    [self presentViewController: imagePicker animated:YES completion:nil]; 
}

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info
{
    typeof(self) w_self = self;
    // 取得照片後，先退出 picker，然後再移到 SellController
    UIImage *image = info[@"UIImagePickerControllerOriginalImage"];
    //    NSLog(@"image size %@", NSStringFromCGSize(image.size));
    [picker dismissViewControllerAnimated:YES completion:^{
        UIImage *imageFixRotation = [CVImageUtil fixrotation:image];
        if(_takePhotoCompleted)_takePhotoCompleted(imageFixRotation);
//        [w_self reloadSceneImage:imageFixRotation];
        _takePhotoCompleted = nil;
    }];
}


- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker
{
    _takePhotoCompleted = nil;
    [picker dismissViewControllerAnimated:YES completion:nil];
}


#pragma mark - CollectionView Data


- (void)addItemPoints:(cv::Point2f*)points size:(int)size refMat:(cv::Mat&)mat descriptString:(NSString*)descString
{
    cv::Mat contoursImg;
    contoursImg.create(mat.rows, mat.cols, CV_8UC1);
    contoursImg.setTo(cv::Scalar(255)); // 背景白色
    cv::Scalar color = cv::Scalar(0); // 畫線黑色
    for(int i = 0; i<size; i++)
    {
        cv::line(contoursImg, points[i], points[(i+1)%size], color);
    }
    [self addItemMat:contoursImg description:descString];
}

- (void)addItemVector:(std::vector<cv::Point>)points refMat:(cv::Mat&)mat descriptString:(NSString*)descString
{
    cv::Mat contoursImg = mat.clone();
    [CVImageUtil drawPointMat:contoursImg points:points];
    [self addItemMat:contoursImg description:descString];
}

- (void)addItemMat:(cv::Mat &)mat description:(NSString*)description
{
    
    UIImage *image = MatToUIImage(mat);
    [self addItem:image description:description];
}

- (void)addItem:(UIImage*)image description:(NSString*)description
{
    CVImageProcessModel *model = [CVImageProcessModel new];
    model.image = image;
    model.descriptionString = description;
    [self addItem:model];
}

- (void)addItem:(CVImageProcessModel*)model
{
    [_itemsList addObject:model];
    [self.collectionView insertItemsAtIndexPaths:@[[NSIndexPath indexPathForRow:_itemsList.count-1 inSection:0]]];
}

- (void)removeAllItem
{
    [_itemsList removeAllObjects];
    [self.collectionView reloadData];
}

#pragma mark - CollectionViewDelegate

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
    return _itemsList.count;
}

- (UICollectionViewCell*)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(nonnull NSIndexPath *)indexPath
{
    CVImageCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"CVImageCell" forIndexPath:indexPath];
    
    [cell onLoad:_itemsList[indexPath.row]];
    
    return cell;
}

@end
