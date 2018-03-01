//
//  ViewController.m
//  OpenCV_featureMatching_demo
//
//  Created by GevinChen on 2018/2/12.
//  Copyright © 2018年 GevinChen. All rights reserved.
//

#import "ViewController.h"
#import "MenuItemCell.h"
#import "HistDemoVC.h"
#import "ORBDemoVC.h"
#import "ORBCameraVC.h"
#import "HaarCascadesVC.h"
#import "MeanShiftVC.h"

@interface ViewController () <UICollectionViewDelegate,UICollectionViewDataSource>
{
    NSMutableArray *_itemsList;
    NSMutableDictionary *_vcDict;
}

@property (weak, nonatomic) IBOutlet UICollectionView *collectionView;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // Do any additional setup after loading the view, typically from a nib.
    self.collectionView.dataSource = self;
    self.collectionView.delegate = self;
    UINib *nib = [UINib nibWithNibName:@"MenuItemCell" bundle:[NSBundle mainBundle]];
    NSArray *views = [nib instantiateWithOwner:nil options:nil];
    MenuItemCell *prototype = views[0];
    [self.collectionView registerNib:nib forCellWithReuseIdentifier:@"MenuItemCell"];
    
    CGSize screenSize = [UIScreen mainScreen].bounds.size;
    UICollectionViewFlowLayout *layout = self.collectionView.collectionViewLayout;
    layout.itemSize = (CGSize){ screenSize.width - 16, prototype.bounds.size.height * (prototype.bounds.size.width/screenSize.width)};

    _itemsList = [NSMutableArray new];
    [_itemsList addObject:@"Histogram"];
    [_itemsList addObject:@"ORB Demo"];
    [_itemsList addObject:@"ORB Camera"];
    [_itemsList addObject:@"Haar Cascade"];
    [_itemsList addObject:@"Mean Shift"];
    
    _vcDict = [[NSMutableDictionary alloc] init];
    _vcDict[@"Histogram"] = [HistDemoVC new];
    _vcDict[@"ORB Demo"] = [ORBDemoVC new];
    _vcDict[@"ORB Camera"] = [ORBCameraVC new];
    _vcDict[@"Haar Cascade"] = [HaarCascadesVC new];
    _vcDict[@"Mean Shift"] = [MeanShiftVC new];
}

#pragma mark - CollectionView

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section{
    return _itemsList.count;
}

- (UICollectionViewCell*)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(nonnull NSIndexPath *)indexPath{
    MenuItemCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"MenuItemCell" forIndexPath:indexPath];
    cell.labelTitle.text = _itemsList[indexPath.row];
    return cell;
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath{
    NSString *title = _itemsList[indexPath.row];
    UIViewController *vc = _vcDict[title];
    if(vc){
        [self presentViewController:vc animated:YES completion:nil];
    }
}

@end
