//
//  SVMDemoVC.m
//  OpenCV_Demo
//
//  Created by GevinChen on 2018/3/2.
//  Copyright © 2018年 GevinChen. All rights reserved.
//

#import "SVMDemoVC.h"

@interface SVMDemoVC ()

@end

@implementation SVMDemoVC

- (void)viewDidLoad {
    [super viewDidLoad];
    
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    [self svmTest];
}

- (IBAction)backClicked:(id)sender
{
    [self dismissViewControllerAnimated:YES completion:nil];
}

//绘制十字架  
-(void)drawCross:(cv::Mat &)img center:(cv::Point)center color:(cv::Scalar)color  
{  
    int col = center.x > 2 ? center.x : 2;  
    int row = center.y> 2 ? center.y : 2;  
    
    line(img, cv::Point(col -2, row - 2), cv::Point(col + 2, row + 2), color);    
    line(img, cv::Point(col + 2, row - 2), cv::Point(col - 2, row + 2), color);    
}  

/* 
 * rows * cols : 訓練數據總數
 * trainCount  : 訓練數據個數 
 */  
-(void)svmTest  
{  
    int cols = 500; // 400
    int rows = 500; // 600
    int trainCount = 2000; // 2000
    if(trainCount > rows * cols)  
        return;  
    
    cv::Mat img = cv::Mat::zeros(rows, cols, CV_8UC3);  
    cv::Mat testPoint = cv::Mat::zeros(rows, cols, CV_8UC1);  
    
    //存放訓練數據 (訓練分類器)，cols 為2，存放 x y 座標，對映到 testPoint 裡的座標點
    cv::Mat trainData = cv::Mat::zeros(trainCount, 2, CV_32FC1);  
    //存放類別標籤 [1,2,3,...]或[-1,+1]，對應 trainData 相同索引的 point，記錄該 point 是什麼分類
    cv::Mat classesData = cv::Mat::zeros(trainCount, 1, CV_32SC1);  
    
    // 設定亂數種子  
    srand(time(NULL));  
    
    //Create random test points  
    //創建樣本數  
    for (int i= 0; i< trainCount; i++){   
        int row = rand() % rows;  
        int col = rand() % cols;  
        if(testPoint.at<unsigned char>(row, col) == 0){  
            testPoint.at<unsigned char>(row, col) = 1;  
            trainData.at<float>(i, 0) = float (col) / cols;  //水平座標(X)  
            trainData.at<float>(i, 1) = float (row) / rows;  //垂直座標(Y)  
        }  
        else{  
            i--;  
            continue;  
        }
        
        if (row > ( 50 * cos(col * CV_PI/ 100) + 200) ){   
            [self drawCross:img center:cv::Point(col, row) color:CV_RGB(255, 0, 0) ];  
            classesData.at<unsigned int>(i, 0) = 1;       //類别1 紅
        }    
        else{
            if (col > 200){   
                [self drawCross:img center:cv::Point(col, row) color:CV_RGB(0, 255, 0) ];  
                classesData.at<unsigned int>(i, 0) = 2;   //類别2 綠
            }   
            else{   
                [self drawCross:img center:cv::Point(col, row) color:CV_RGB(0, 0, 255) ];  
                classesData.at<unsigned int>(i, 0) = 3;   //類别3 藍
            }
        }
    }
    
    [self addItemMat:img description:@"訓練樣本"];
    
    CvSVM svm;   
    CvSVMParams param;   
    CvTermCriteria criteria;  
    //epsilon, 迭代次數=1000，epsilon=FLT_EPSILON  
    criteria= cvTermCriteria(CV_TERMCRIT_EPS, 1000, FLT_EPSILON);
    
    /* 
     struct CV_EXPORTS_W_MAP CvSVMParams 
     { 
     CvSVMParams(); 
     CvSVMParams( int svm_type, int kernel_type, 
     double degree, double gamma, double coef0, 
     double Cvalue, double nu, double p, 
     CvMat* class_weights, CvTermCriteria term_crit ); 
     
     CV_PROP_RW int         svm_type; 
     CV_PROP_RW int         kernel_type; 
     CV_PROP_RW double      degree; // for poly 
     CV_PROP_RW double      gamma;  // for poly/rbf/sigmoid 
     CV_PROP_RW double      coef0;  // for poly/sigmoid 
     
     CV_PROP_RW double      C;  // for CV_SVM_C_SVC, CV_SVM_EPS_SVR and CV_SVM_NU_SVR 
     CV_PROP_RW double      nu; // for CV_SVM_NU_SVC, CV_SVM_ONE_CLASS, and CV_SVM_NU_SVR 
     CV_PROP_RW double      p; // for CV_SVM_EPS_SVR 
     CvMat*      class_weights; // for CV_SVM_C_SVC 
     CV_PROP_RW CvTermCriteria term_crit; // termination criteria 
     }; 
     
     */  
    // 設定 svm 參數： SVM類型-C_SVC, kernel方法-RBF,degree=10,gamma=8.0, coef0=1.0,C=10.0,nu=0.5,p=0.1,class_weights=NULL,term_crit=criteria  
    param = CvSVMParams (CvSVM::C_SVC,  // SVM 類型，C_SVC，NU_SVC，ONE_CLASS，EPS_SVR，NU_SVR
                         CvSVM::RBF,    // 內核函數類型，LINEAR，POLY，RBF，SIGMOID
                         10,            // degree 内核函數（POLY）的参數degree
                         8,             // gamma  内核函數（POLY/ RBF/ SIGMOID）的参數
                         1,             // coef0  内核函數（POLY/ SIGMOID）的参數coef0
                         10,            // C value 懲罰錯誤分類值，SVM類型 (C_SVC/ EPS_SVR/ NU_SVR) 的参數 C，懲罰錯誤分類，值越高，界線劃分越嚴謹
                         0.5,           // nu SVM類型（NU_SVC/ ONE_CLASS/ NU_SVR）的参數 
                         0.1,           // p SVM類型（EPS_SVR）的参數
                         NULL,          // class_weights C_SVC中的可選權重，賦給指定的label，乘以C以後，權重影響不同類別的錯誤分類懲罰項。權重越大，某一類別的錯誤分類數據的懲罰項就越大。
                         criteria);     // 訓練終止的條件參數
    // 用 trainData 訓練分類器，classesData 是每筆訓練資料的分類
    svm.train(trainData, classesData, cv::Mat(), cv::Mat(), param);  
    

    for (int i= 0; i< rows; i++){
        for (int j= 0; j< cols; j++){   
            cv::Mat m = cv::Mat::zeros(1, 2, CV_32FC1);  
            // 產生測試樣本
            m.at<float>(0,0) = float (j) / cols;  
            m.at<float>(0,1) = float (i) / rows;  
            
            float ret = 0.0;   
            // 對資料進行預測判斷，回傳該資料屬於哪個分類  
            ret = svm.predict(m);   
            cv::Scalar rcolor;   
            
            switch ((int) ret){   
                case 1: rcolor= CV_RGB(100, 0, 0); break;   
                case 2: rcolor= CV_RGB(0, 100, 0); break;   
                case 3: rcolor= CV_RGB(0, 0, 100); break;   
            }   
            
            cv::line(img, cv::Point(j,i), cv::Point(j,i), rcolor);  
        }   
    }  
    
    [self addItemMat:img description:@"分類結果"];
    
    //Show support vectors  
    //顯示
    int sv_num= svm.get_support_vector_count();   
    for (int i= 0; i< sv_num; i++){   
        const float* support = svm.get_support_vector(i);   
        cv::circle(img, cv::Point((int) (support[0] * cols), (int) (support[1] * rows)), 5, CV_RGB(200, 200, 200));   
    }  
    
    [self addItemMat:img description:@"顯示支持向量"];
 
}  



/*
#define TRAIN_SAMPLE_COUNT 50
#define SIGMA 60

- (void)svmDemo
{
    //Setup Matrices for TrainData set and Class Labels.
    //Most of OpenCV Machine Learning algorithms accept CV_32FC1 matrix format as their input/ouput
    CvMat *trainClass = cvCreateMat(TRAIN_SAMPLE_COUNT,1,CV_32FC1);
    CvMat *trainData = cvCreateMat(TRAIN_SAMPLE_COUNT,2,CV_32FC1);
    //  cvCreateMat(列數數據,行數數據,CvMat資料結構參數)
    
    //Creating a image to represent outputs
    IplImage *frame  = cvCreateImage(cvSize(500,700), IPL_DEPTH_8U, 3);
    //a vector to use for predicting data
    CvMat *sample = cvCreateMat(1,2,CV_32FC1);
    
    //Setting up Train Data
    CvMat subtrainData;
    cvGetRows(trainData,&subtrainData,0,TRAIN_SAMPLE_COUNT/3);
    
    CvRNG rng_state = cvRNG(-1);
    //  cvGetTickCount()系統時間數據
    //  cvRNG()亂數產生器
    
    CvMat trainData_col;
    cvGetCols(&subtrainData,&trainData_col,0,1);
    cvRandArr(&rng_state,&trainData_col,CV_RAND_NORMAL,cvScalar(100),cvScalar(SIGMA));
    cvGetCols(&subtrainData,&trainData_col,1,2);
    cvRandArr(&rng_state,&trainData_col,CV_RAND_NORMAL,cvScalar(300),cvScalar(SIGMA));
    //  cvRandArr(CvRNG資料結構,IplImage或CvMat資料結構,均勻分佈參數,隨機範圍下限,隨機範圍上限)
    //  cvRandArr(CvRNG資料結構,IplImage或CvMat資料結構,常態分佈參數,平均數,標準差)
    //  cvGetRows(IplImage資料結構或CvMat資料結構,空的CvMat資料結構,開始列數Int型別,結束列數Int型別)
    //  cvGetCols(IplImage資料結構或CvMat資料結構,空的CvMat資料結構,開始欄數Int型別,結束欄數Int型別)
    
    cvGetRows(&trainData,&subtrainData,TRAIN_SAMPLE_COUNT/3,2*TRAIN_SAMPLE_COUNT/3);
    cvRandArr(&rng_state,&subtrainData,CV_RAND_NORMAL,cvScalar(400),cvScalar(SIGMA));
    
    cvGetRows(trainData,&subtrainData,2*TRAIN_SAMPLE_COUNT/3,TRAIN_SAMPLE_COUNT);
    
    cvGetCols(&subtrainData,&trainData_col,0,1);
    cvRandArr(&rng_state,&trainData_col,CV_RAND_NORMAL,cvScalar(300),cvScalar(SIGMA));
    cvGetCols(&subtrainData,&trainData_col,1,2);
    cvRandArr(&rng_state,&trainData_col,CV_RAND_NORMAL,cvScalar(100),cvScalar(SIGMA));
    
    //Setting up train classes
    CvMat subclassData;
    cvGetRows(trainClass,&subclassData,0,TRAIN_SAMPLE_COUNT/3);
    cvSet(&subclassData,cvScalar(1));
    cvGetRows(trainClass,&subclassData,TRAIN_SAMPLE_COUNT/3,2*TRAIN_SAMPLE_COUNT/3);
    cvSet(&subclassData,cvScalar(2));
    cvGetRows(trainClass,&subclassData,2*TRAIN_SAMPLE_COUNT/3,TRAIN_SAMPLE_COUNT);
    cvSet(&subclassData,cvScalar(3));
    
    //Setting up SVM parameters
    CvSVMParams params;
    params.kernel_type=CvSVM::LINEAR;
    params.svm_type=CvSVM::C_SVC;
    params.C=1;
    params.term_crit=cvTermCriteria(CV_TERMCRIT_ITER,100,0.000001);
    CvSVM svm;
    
    //Training the model
    bool res=svm.train(trainData,trainClass,CvMat(),CvMat(),params);
    
    //using the model to to pridict some data
    for (int i = 0; i < frame->height; i++)
    {
        for (int j = 0; j < frame->width; j++)
        {
            //setting sample data values
            *((float*)CV_MAT_ELEM_PTR(*sample,0,0)) = j;
            *((float*)CV_MAT_ELEM_PTR(*sample,0,1)) = i;
            
            float response = svm.predict(sample);
            uchar *ptr = (uchar *) (frame->imageData + i * frame->widthStep);
            //checking class labels against predicted class.
            if(response == 1)
            {
                ptr[3*j]= 255;
                ptr[3*j+1] = 100;
                ptr[3*j+2] = 100;
            }
            if(response == 2)
            {
                ptr[3*j]= 100;
                ptr[3*j+1] = 255;
                ptr[3*j+2] = 100;
            }
            if(response == 3)
            {
                ptr[3*j]= 100;
                ptr[3*j+1] = 100;
                ptr[3*j+2] = 255;
            }
        }
    }
    //making all sample points visible on the image.
    for (int i = 0; i < (TRAIN_SAMPLE_COUNT / 3); i++)
    {
        CvPoint2D32f p1 = cvPoint2D32f(CV_MAT_ELEM(*trainData,float,i,0),CV_MAT_ELEM(*trainData,float,i,1));
        cvDrawCircle(frame,cvPointFrom32f(p1),2,cvScalar(255, 0, 0),-1);
        CvPoint2D32f p2 = cvPoint2D32f(CV_MAT_ELEM(*trainData,float,TRAIN_SAMPLE_COUNT / 3+i,0),CV_MAT_ELEM(*trainData,float,TRAIN_SAMPLE_COUNT / 3+i,1));
        cvDrawCircle(frame,cvPointFrom32f(p2),2,cvScalar(0, 255, 0),-1);
        CvPoint2D32f p3 = cvPoint2D32f(CV_MAT_ELEM(*trainData,float,2*TRAIN_SAMPLE_COUNT / 3+i,0),CV_MAT_ELEM(*trainData,float,2*TRAIN_SAMPLE_COUNT / 3+i,1));
        cvDrawCircle(frame,cvPointFrom32f(p3),2,cvScalar(0, 0, 255),-1);
    }
    //Showing support vectors
    int c = svm.get_support_vector_count();
    for (int i = 0; i < c; i++)
    {
        const float *v = svm.get_support_vector(i);
        CvPoint2D32f p1 = cvPoint2D32f(v[0], v[1]);
        cvDrawCircle(frame,cvPointFrom32f(p1),4,cvScalar(128, 128, 128),2);
    }
//    cvNamedWindow( "SVM Tutorial", CV_WINDOW_AUTOSIZE );
//    cvShowImage( "SVM Tutorial", frame );
//    cvWaitKey();
}
*/

@end
