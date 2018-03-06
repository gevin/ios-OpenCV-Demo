//
//  HOGAndSvmVC.m
//  OpenCV_Demo
//
//  Created by GevinChen on 2018/3/3.
//  Copyright © 2018年 GevinChen. All rights reserved.
//

#import "HOGAndSvmVC.h"

/*
 繼承 cv::SVM，因為 hog 的 setSVMDetector()，設定檢測子參數，需要用到訓練好的 SVM的decision_func 參數
 但通過查看 cv::SVM source code 可以看到 decision_func 是 protected 類型，無法直接取得，只能繼承後通過
 自訂函數取得。
 */
class MySVM : public cv::SVM
{
public:
    // 取得 SVM 的決策函數中的alpha數組
    double * get_alpha_vector()
    {
        return this->decision_func->alpha;
    }
    // 取得 SVM 的決策函數中的 rho 參數,即偏移量
    float get_rho()
    {
        return this->decision_func->rho;
    }
};


@interface HOGAndSvmVC ()< CvVideoCameraDelegate >
{
    CvVideoCamera *camera;
    MySVM _svm;
    cv::HOGDescriptor _hog;
    UIActivityIndicatorView *_spinnerView;
    
    BOOL _start;
    BOOL _hasModel;
    BOOL _initPersonDetector;
    NSThread *_thread;
}
@property (weak, nonatomic) IBOutlet UIImageView *imageView;
@property (weak, nonatomic) IBOutlet UILabel *labelModelState;
@property (weak, nonatomic) IBOutlet UIButton *btnTrain;
@property (weak, nonatomic) IBOutlet UIButton *btnStart;
@property (weak, nonatomic) IBOutlet UIButton *btnBack;
@property (weak, nonatomic) IBOutlet UIButton *btnTest1;
@property (weak, nonatomic) IBOutlet UIButton *btnTest2;
@end

@implementation HOGAndSvmVC

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
    
    _spinnerView = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
    
    NSString *model_path = [self trainModelPath];
    if([[NSFileManager defaultManager] fileExistsAtPath:model_path]){
        [self setHasModel:YES];
    }
    else{
        [self setHasModel:NO];
    }
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
//    if([self hasModel]){
//        [self initPersonDetector];
//    }
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    [camera stop];
    if(_thread){
        [_thread cancel];
    }
}

#pragma mark - Button Action

- (IBAction)btnStartClicked:(id)sender {
    if(_hasModel){
        [self initPersonDetector];

        self.btnStart.selected = !self.btnStart.selected;
        _start = self.btnStart.selected;
        if(_start){
            [camera start];
        }
        else{
            [camera stop];
        }
    }
}

- (IBAction)btnBackClicked:(id)sender {
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (IBAction)btnTrainClick:(id)sender {
    
    if (_thread==nil && !_hasModel) {
        _thread = [[NSThread alloc] initWithTarget:self selector:@selector(hogSvmTraining) object:nil];
        [_thread start];
    }
    else if(_hasModel && _thread == nil ){
        NSString *path = [self trainModelPath];
        [[NSFileManager defaultManager] removeItemAtPath:path error:nil];
        if([[NSFileManager defaultManager] fileExistsAtPath:path]){
            [self setHasModel:YES];
        }
        else{
            [self setHasModel:NO];
        }
    }
}

- (IBAction)btnTest1Clicked:(id)sender {
    if(_start) return;
    if(!_initPersonDetector){
        [self initPersonDetector];
    }
    UIImage *pos_img = [UIImage imageNamed:@"test_person_pos1.png"];
    [self detectPerson:pos_img];
}

- (IBAction)btnTest2Clicked:(id)sender {
    if(_start) return;
    if(!_initPersonDetector){
        [self initPersonDetector];
    }
    UIImage *pos_img = [UIImage imageNamed:@"test_person_pos2.png"];
    [self detectPerson:pos_img];
}



#pragma mark - Property

- (void)setHasModel:(BOOL)hasmodel
{
    _hasModel = hasmodel;
    if(_hasModel){
        self.labelModelState.text = @"model exist.";
        [self.btnTrain setTitle:@"Delete" forState:UIControlStateNormal];
    }
    else{
        self.labelModelState.text = @"should train model";
        [self.btnTrain setTitle:@"Train" forState:UIControlStateNormal];
    }
}

- (BOOL)hasModel
{
    return _hasModel;
}

-(void)disableButtons
{
    self.btnTrain.enabled = NO;
    self.btnStart.enabled = NO;
    self.btnTest1.enabled = NO;
    self.btnTest2.enabled = NO;
}

- (void)enableButtons
{
    self.btnTrain.enabled = YES;
    self.btnStart.enabled = YES;
    self.btnTest1.enabled = YES;
    self.btnTest2.enabled = YES;    
}

#pragma mark - SVM


- (void)hogSvmTraining
{
    //-----------------------------------------
    //  start handle
    //-----------------------------------------
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.view addSubview:_spinnerView];
        self.labelModelState.text = @"training...";
        _spinnerView.center = self.view.center;
        [_spinnerView startAnimating];
        [self disableButtons];
    });
    
    cv::Mat train_data;
    cv::Mat train_labels;
    
    //-----------------------------------------
    //  get train pic name 
    //-----------------------------------------
    printf("get positive image name list.\n");
    // 讀取正樣本圖片名字清單
    NSMutableArray *pos_img_paths = [[[NSBundle mainBundle] pathsForResourcesOfType:@".png" inDirectory:@"person_train/pos"] mutableCopy];
    NSArray *pos_img_paths2 = [[NSBundle mainBundle] pathsForResourcesOfType:@".jpg" inDirectory:@"person_train/pos"];
    [pos_img_paths addObjectsFromArray:pos_img_paths2];
    NSMutableArray *pos_img_names = [[NSMutableArray alloc] init]; 
    for (NSString *path in pos_img_paths) {
        NSString *name = [[path componentsSeparatedByString:@"/"] lastObject];
        name = [NSString stringWithFormat:@"person_train/pos/%@", name ];
        [pos_img_names addObject:name];
    }
    printf("positive image count:%d.\n", pos_img_names.count);
    
    printf("get negitive image name list.\n");
    // 讀取負樣本圖片名字清單
    NSMutableArray *neg_img_paths = [[[NSBundle mainBundle] pathsForResourcesOfType:@".png" inDirectory:@"person_train/neg"] mutableCopy];
    NSArray *neg_img_paths2 = [[NSBundle mainBundle] pathsForResourcesOfType:@".jpg" inDirectory:@"person_train/neg"];
    [neg_img_paths addObjectsFromArray:neg_img_paths2];
    NSMutableArray *neg_img_names = [[NSMutableArray alloc] init]; 
    for (NSString *path in neg_img_paths) {
        NSString *name = [[path componentsSeparatedByString:@"/"] lastObject];
        name = [NSString stringWithFormat:@"person_train/neg/%@", name ];
        [neg_img_names addObject:name];
    }
    printf("negitive image count:%d.\n", neg_img_names.count);
    
    int pos_img_count = pos_img_names.count;
    int neg_img_count = neg_img_names.count;
    BOOL trainDataInit = NO;
    int descriptorDim = 0;
    printf("init hog.\n");
    
    //-----------------------------------------
    //  init hog descriptor 
    //-----------------------------------------
    // 檢測窗口(64,128), block size(16,16)cell, 移動步長(8,8),cell尺寸(8,8),直方圖bin個數 9
    cv::HOGDescriptor *hog = new cv::HOGDescriptor( cv::Size(64,128), cv::Size(16,16),cv::Size(8,8),cv::Size(8,8),9);
    
    printf("extract positive image feature.\n");
    // 讀取正樣本，生成 hog 描述子
    int index = 0;
    for ( NSString *img_name in pos_img_names) {
        printf("+ %s\n",[img_name UTF8String]);

        //-----------------------------------------
        //  load training positive image
        //-----------------------------------------
        UIImage *image = [UIImage imageNamed:img_name];
        cv::Mat imgM;
        UIImageToMat(image, imgM);
        cv::cvtColor(imgM, imgM, CV_BGR2GRAY);
        
        // 上下左右剪去16，原圖 96*160
        imgM = imgM(cv::Rect( (imgM.cols-64)/2, (imgM.rows-128)/2,64,128));
        
        //-----------------------------------------
        //  extract image feature
        //-----------------------------------------
        std::vector<float> descriptors;//HOG描述子向量
        // hog extract feature
        hog->compute(imgM, descriptors, cv::Size(8,8));
        
        //-----------------------------------------
        //  save feature into train_data Mat
        //  and assign label
        //-----------------------------------------
        // init mat, cause know the dim after extract feature 
        if(!trainDataInit){
            descriptorDim = descriptors.size();
            train_data = cv::Mat::zeros( pos_img_count + neg_img_count, descriptorDim, CV_32FC1);
            train_labels = cv::Mat::zeros( pos_img_count + neg_img_count, 1, CV_32FC1);
        }
        // save feature descriptor data to training_data
        for(int i=0; i<descriptorDim; i++){
            train_data.at<float>(index,i) = descriptors[i];//第 index 个样本的特征向量中的第i个元素
        }
        // save 1 label to trainning_labels
        train_labels.at<float>(index,0) = 1;//正樣本為1，有人
        
        descriptors.clear();
        imgM.release();
        image = nil;

        index++;
    }
    
    printf("extract negitive image feature.\n");
    srand(time(NULL));
    // 讀取負樣本，生成 hog 描述子
    index = 0;
    for ( NSString *img_name in neg_img_names) {
        printf("- %s\n",[img_name UTF8String]);
        //-----------------------------------------
        //  load training negitive image
        //-----------------------------------------
        UIImage *image = [UIImage imageNamed:img_name];
        if(image == nil){
            printf("image nil\n");
        }
        cv::Mat imgM;
        UIImageToMat(image, imgM);
        cv::cvtColor(imgM, imgM, CV_BGR2GRAY);
        
        float scale_h = 64.0/imgM.cols;
        float scale_v = 128.0/imgM.rows;
        if( imgM.rows * scale_h > 128.0){
            cv::resize(imgM, imgM, cv::Size( 64, imgM.rows * scale_h) );
        }
        else if( imgM.cols * scale_v > 64.0){
            cv::resize(imgM, imgM, cv::Size( imgM.cols * scale_v, 128) );
        }
        
        // 隨機取 64*128
        int x = (imgM.cols-64)/2;
        int y = (imgM.rows-128)/2;
        imgM = imgM(cv::Rect( x, y, 64,128) );
        
        //-----------------------------------------
        //  extract image feature
        //-----------------------------------------
        // HOG描述資料
        std::vector<float> descriptors;
        // 計算 hog 描述子，檢測窗口移動步長 8*8 pixels
        hog->compute(imgM,descriptors,cv::Size(8,8));
        
        //-----------------------------------------
        //  save feature into train_data Mat
        //  and assign label
        //-----------------------------------------
        // save feature descriptor data to training_data
        for(int i=0; i<descriptorDim; i++)
            train_data.at<float>(index+pos_img_count,index) = descriptors[i];
        
        // save 1 label to trainning_labels
        train_labels.at<float>(index+pos_img_count,0) = -1;//負樣本為-1，無人
        
        descriptors.clear();
        imgM.release();
        image = nil;
        index++;
    }
    printf("init svm\n");
    
    //-----------------------------------------
    //  train svm
    //-----------------------------------------
    // train svm
    cv::SVM svm;
    // 迭代終止條件，當迭代滿1000次，或誤差小於FLT_EPSILON時，停止迭代
    CvTermCriteria criteria = cvTermCriteria(CV_TERMCRIT_ITER+CV_TERMCRIT_EPS, 1000, FLT_EPSILON);
    // SVM參數 SVM類型:C_SVC，kernel函數:線性，松弛因子C=0.01
    CvSVMParams param(CvSVM::C_SVC,  // SVM 類型，C_SVC，NU_SVC，ONE_CLASS，EPS_SVR，NU_SVR
                      CvSVM::LINEAR, // 內核函數類型，LINEAR，POLY，RBF，SIGMOID
                      0,             // degree 内核函數（POLY）的参數degree
                      1,             // gamma  内核函數（POLY/ RBF/ SIGMOID）的参數
                      0,             // coef0  内核函數（POLY/ SIGMOID）的参數coef0
                      0.01,          // C value 鬆弛因子，SVM類型（C_SVC/ EPS_SVR/ NU_SVR）的参數 C
                      0,             // nu SVM類型（NU_SVC/ ONE_CLASS/ NU_SVR）的参數 
                      0,             // p SVM類型（EPS_SVR）的参數
                      NULL,          // class_weights C_SVC中的可選權重，賦給指定的label，乘以C以後，權重影響不同類別的錯誤分類懲罰項。權重越大，某一類別的錯誤分類數據的懲罰項就越大。
                      criteria);     // 訓練終止的條件參數
    printf("training!!!\n");
    // 訓練分類器
    svm.train(train_data, train_labels, cv::Mat(), cv::Mat(), param);
    // 訓練完成
    printf("training completed!!!!\n");
    
    //-----------------------------------------
    //  save svm model
    //-----------------------------------------
    // 儲存訓練完成的模型
    NSString *path = [self trainModelPath];
    svm.save([path UTF8String]);
    
    delete hog;
    train_data.release();
    train_labels.release();
    [pos_img_paths removeAllObjects];
    [neg_img_paths removeAllObjects];
    [pos_img_names removeAllObjects];
    [neg_img_names removeAllObjects];
    
    //-----------------------------------------
    //  completed handle
    //-----------------------------------------
    dispatch_async(dispatch_get_main_queue(), ^{
        [self setHasModel:YES];
        [_spinnerView stopAnimating];
        _thread = nil;
        [self enableButtons];
        [self initPersonDetector];
    });
}

- (void)initPersonDetector
{
    if(_initPersonDetector || !_hasModel) return;
    _initPersonDetector = YES;
    /*
     性線 SVM 訓練完成後得到的 xml 文件裡，有一組數據，叫 support vector，還有一組數據叫 alpha，還有另一個叫 rho
     訓練完的分類器函數即為 (support vector Mat * alpha Mat) + rho
     
     hog.setSVMDetector() 中，要傳入的檢測子，即為上述的分類器，把 (support vector Mat * alpha Mat) + rho 傳入後
     即可用 hog.detectMultiScale() 進行檢測
     
     Gevin note:
     目前 train 出來的結果，根本沒辦法用，偵測不到行人，不確定是哪裡出問題
     */
    
//    NSString *path = [self trainModelPath];
//    _svm.load([path UTF8String]);
//    
//    int descriptorDim = _svm.get_var_count();//特徵向量的維數，即HOG描述子的維數
//    int supportVectorNum = _svm.get_support_vector_count();//支持向量的個數
//    printf("支持向量數：%d\n",supportVectorNum);
//    cv::Mat alphaMat = cv::Mat::zeros(1, supportVectorNum, CV_32FC1);//alpha向量，長度等於支持向量個數
//    cv::Mat supportVectorMat = cv::Mat::zeros(supportVectorNum, descriptorDim, CV_32FC1);//支持向量矩陣
//    cv::Mat resultMat = cv::Mat::zeros(1, descriptorDim, CV_32FC1);//alpha向量乘以支持向量矩陣的结果
//    //將支持向量資料複製到支持向量矩陣中
//    for(int i=0; i<supportVectorNum; i++){
//        const float * pSVData = _svm.get_support_vector(i);
//        for(int j=0; j<descriptorDim; j++){
//            //cout<<pData[j]<<" ";
//            supportVectorMat.at<float>(i,j) = pSVData[j];
//        }
//    }
//    //將alpha向量的資料複製到alphaMat中
//    double * pAlphaData = _svm.get_alpha_vector();
//    for(int i=0; i<supportVectorNum; i++){
//        alphaMat.at<float>(0,i) = pAlphaData[i];
//    }
//    //計算-(alphaMat * supportVectorMat),結果放到resultMat中
//    resultMat = -1 * alphaMat * supportVectorMat;
//    //得到最終的 setSVMDetector(const vector<float>& detector) 參數中可用的檢測子
//    std::vector<float> myDetector;
//    for(int i=0; i<descriptorDim; i++){
//        myDetector.push_back(resultMat.at<float>(0,i));
//    }
//    // 最後添加偏移量rho，得到檢測子
//    myDetector.push_back(_svm.get_rho());
//    printf("檢測子維數：%lu\n",myDetector.size());
//    //設置 HOGDescriptor 的檢測子
//    _hog = cv::HOGDescriptor(cv::Size(64,128), cv::Size(16,16), cv::Size(8,8), cv::Size(8,8), 9);
//    _hog.setSVMDetector(myDetector);
    
    printf("預設檢測子維數：%lu\n",cv::HOGDescriptor::getDefaultPeopleDetector().size());
    _hog = cv::HOGDescriptor(cv::Size(64,128), // windows size 
                             cv::Size(16,16),  // block size 16*16 pixels，必須要是 cell 的size 的倍數
                             cv::Size(8,8),    // block stride 移步 8*8 pixels
                             cv::Size(8,8),    // cell size, 8*8 pixels
                             9);               // bins 一個Cell有9個方向，共9維
    _hog.setSVMDetector(cv::HOGDescriptor::getDefaultPeopleDetector());
    
/*        
 SVM种类：CvSVM::C_SVC        
 Kernel的种类：CvSVM::RBF        
 degree：10.0（此次不使用）        
 gamma：8.0        
 coef0：1.0（此次不使用）        
 C：10.0        
 nu：0.5（此次不使用）        
 p：0.1（此次不使用）        
 然后对训练数据正规化处理，并放在CvMat型的数组里。        
 */
}

- (void)detectPerson:(UIImage*)image
{
    cv::Mat testImgM;
    cv::Mat testImgM_gray;
    UIImageToMat(image, testImgM);
    cv::cvtColor(testImgM, testImgM_gray, CV_BGR2GRAY);
    
    std::vector<cv::Rect> found, found_filtered;//矩形框数组
    printf("進行多尺寸檢測\n");
    _hog.detectMultiScale(testImgM_gray, found, 0, cv::Size(8,8), cv::Size(32,32), 1.05, 2);//对图片进行多尺度行人检测
    printf("找到的矩形框數:%lu\n",found.size());
    // 畫框
    for(int i=0; i<found.size(); i++){
        cv::Rect r = found[i];
        rectangle(testImgM, r.tl(), r.br(), cv::Scalar(0,255,0), 3);
    }
    
    UIImage *resultImg = MatToUIImage(testImgM);
    self.imageView.image = resultImg;
}

#pragma mark - Camera Raw Data

-(void)processImage:(cv::Mat &)image
{ 
    if (!_start) return;

    cv::Mat gray_image;
    cv::cvtColor(image, gray_image, CV_BGR2GRAY);
    // 把 image 縮小，以增加檢測的效能
    cv::resize(gray_image, gray_image, cv::Size(gray_image.cols * 0.5, gray_image.rows * 0.5 ));
    
    std::vector<cv::Rect> found;
    // 檢測
    // window stride 8*8, padding 32*32
    _hog.detectMultiScale(gray_image, found, 0, cv::Size(8,8), cv::Size(32,32), 1.05, 2);
    
    // 顯示
    for(int i=0; i<found.size(); i++){
        cv::Rect r = found[i];
        r = cv::Rect(r.x*2,r.y*2, r.width*2, r.height*2);
        rectangle(image, r.tl(), r.br(), cv::Scalar(0,255,0), 1);
    }
}  

- (NSString*)trainModelPath{
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *basePath = paths.firstObject;
    NSString *path = [basePath stringByAppendingPathComponent:@"SVM_Person_HOG.xml"];
    return path;
}

@end
