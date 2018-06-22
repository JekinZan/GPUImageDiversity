//
//  ViewController.m
//  GPUIamgeTest
//
//  Created by zhangjie on 2018/6/20.
//  Copyright © 2018年 zhangjie. All rights reserved.
//

#import "GPURecorWaterMarkViewController.h"
#import <GPUImage.h>
#import "FouncationView.h"
#import <VideoToolbox/VideoToolbox.h>
#import "JKGPUImageVideoCamera.h"
#import "JKGPUImageCaptureDataHandler.h"
typedef enum {
    PASSTHROUGH_VIDEO,
    SIMPLE_THRESHOLDING,
    POSITION_THRESHOLDING,
    OBJECT_TRACKING
} ColorTrackingDisplayMode;
@interface GPURecorWaterMarkViewController () {
    @protected
    NSString *_pathMove;
}
@property (weak, nonatomic) IBOutlet UISegmentedControl *optionSegument;
@property (weak, nonatomic) IBOutlet UIButton *startButton;
@property (nonatomic,strong) GPUImageUIElement *element;
@property (nonatomic,strong) GPUImageFilter *alphaFilter;
@property (nonatomic,strong) GPUImageView *filteredVideoView;
@property (nonatomic,strong) JKGPUImageVideoCamera *videoCamera;//当前模式,一开始为视频
@property (nonatomic,strong) GPUImageMovieWriter *movieWriter;//写入视频
@property (nonatomic,strong) JKGPUImageCaptureDataHandler *dataHandler;//处理音视频的类
@property (weak, nonatomic) IBOutlet UIButton *warterMarkBtn;
@property (weak, nonatomic) IBOutlet UIButton *removeMarkBtn;
    @property (weak, nonatomic) IBOutlet UIButton *flowBtn;
    @property (nonatomic,strong) UIImageView *imageView;
@end

@implementation GPURecorWaterMarkViewController


- (void)viewDidLoad {
    [super viewDidLoad];
    [self configureVideoFiltering];
    [self.view bringSubviewToFront:self.optionSegument];
    [self.view bringSubviewToFront:self.startButton];
    [self.view bringSubviewToFront:self.warterMarkBtn];
    [self.view bringSubviewToFront:self.removeMarkBtn];
    [self.view bringSubviewToFront:self.flowBtn];
}

- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    // 获取点击位置
    UITouch *touch = [touches anyObject];
    CGPoint point = [touch locationInView:_filteredVideoView];
     CGPoint cameraPoint = [_videoCamera.videoCaptureConnection.videoPreviewLayer captureDevicePointOfInterestForPoint:point];
    [self focusWithMode:AVCaptureFocusModeAutoFocus exposureMode:AVCaptureExposureModeAutoExpose atPoint:cameraPoint];
}
- (IBAction)actionForFlowBtn:(id)sender {
    if(self.optionSegument.selectedSegmentIndex == 1)return;
    _dataHandler = [[JKGPUImageCaptureDataHandler alloc]initWithImageSize:[UIScreen mainScreen].bounds.size resultsInBGRAFormat:YES];
    _videoCamera.audioMetaDelegate = _dataHandler;
    [_videoCamera addTarget:_dataHandler];
}
- (IBAction)actionForStartBtn:(UIButton *)sender {
    sender.selected = !sender.selected;
    if (sender.selected == YES) {//表示开始录制或者拍照
        if ([self.videoCamera isMemberOfClass:[GPUImageStillCamera class]]) {//拍照模式
            GPUImageStillCamera *imageCamera = (GPUImageStillCamera *)self.videoCamera;
            [imageCamera capturePhotoAsImageProcessedUpToFilter:self.alphaFilter withCompletionHandler:^(UIImage *processedImage, NSError *error) {
                if (error)return ;
               UIImageWriteToSavedPhotosAlbum(processedImage, nil, nil, nil);
            }];
        }else {//录像模式
            [self startRecordVider];
        }
    }else {//结束录制或者拍照
        [self endRecordVider];
    }
}
- (IBAction)actionForMark:(id)sender {
    [_videoCamera removeAllTargets];
    
    GPUImageFilter *filter = [[GPUImageFilter alloc]init];
    [self.videoCamera addTarget:filter];
    self.alphaFilter = [GPUImageNormalBlendFilter new];
    
    [filter addTarget:self.alphaFilter];
    [self.element addTarget:self.alphaFilter];
    [self.alphaFilter addTarget:_filteredVideoView];
    __weak typeof(self)weakself = self;
    //添加水印必须执行此回调刷新水印
    [filter setFrameProcessingCompletionBlock:^(GPUImageOutput *output, CMTime time) {
        __strong typeof(self)strongself = weakself;
        [strongself.element update];
    }];
}
- (IBAction)actionForSegument:(UISegmentedControl *)sender {
    [self.videoCamera stopCameraCapture];
    _videoCamera = nil;
    [self resetVideoCamera];
    [self.videoCamera startCameraCapture];
}
- (IBAction)actionForRemove:(id)sender {
    _element = nil;
    [self resetVideoCamera];
}

- (void)resetVideoCamera {
    [self.videoCamera removeAllTargets];//1
    [_alphaFilter removeAllTargets];//5
    _alphaFilter = nil;//4
    [self.videoCamera addTarget:self.alphaFilter];//2
    [self.alphaFilter addTarget:self.filteredVideoView];//3;
}


- (void)startRecordVider {
    NSTimeInterval time = [NSDate date].timeIntervalSinceReferenceDate;
    _pathMove = [NSHomeDirectory() stringByAppendingPathComponent:[NSString stringWithFormat:@"Documents/Movie%lf.m4v",time]];
    unlink([_pathMove UTF8String]);
    _movieWriter = [[GPUImageMovieWriter alloc]initWithMovieURL:[NSURL fileURLWithPath:_pathMove] size:[UIScreen mainScreen].bounds.size];
    _videoCamera.audioEncodingTarget = _movieWriter;
    _movieWriter.encodingLiveVideo = YES;
    _movieWriter.shouldPassthroughAudio = YES;
    _movieWriter.hasAudioTrack = YES;
    _movieWriter.completionBlock = ^{
        NSLog(@"录制成功");
    };
    _movieWriter.failureBlock = ^(NSError *error) {
        NSLog(@"录制失败");
    };
    if (_alphaFilter) {
        [self.alphaFilter addTarget:_movieWriter];
    }else {
        [_videoCamera addTarget:_movieWriter];
    }
    [_movieWriter startRecording];
}

- (void)endRecordVider {
    if ([_videoCamera isMemberOfClass:[GPUImageStillCamera class]])return;
    _videoCamera.audioEncodingTarget = nil;
    [_movieWriter finishRecording];
    [_videoCamera removeTarget:_movieWriter];
    UISaveVideoAtPathToSavedPhotosAlbum(_pathMove, nil, nil, nil);
}
#pragma mark - privateMethod
//配置摄像头
- (void)configureVideoFiltering {
    [self.view addSubview:self.filteredVideoView];
    [self.videoCamera addTarget:self.alphaFilter];
    [self.alphaFilter addTarget:self.filteredVideoView];
    [self.videoCamera startCameraCapture];
}

-(void)focusWithMode:(AVCaptureFocusMode)focusMode exposureMode:(AVCaptureExposureMode)exposureMode atPoint:(CGPoint)point {
    
    AVCaptureDevice *captureDevice = _videoCamera.inputCamera;
    // 锁定配置
    [captureDevice lockForConfiguration:nil];
    
    // 设置聚焦
    if ([captureDevice isFocusModeSupported:AVCaptureFocusModeAutoFocus]) {
        [captureDevice setFocusMode:AVCaptureFocusModeAutoFocus];
    }
    if ([captureDevice isFocusPointOfInterestSupported]) {
        [captureDevice setFocusPointOfInterest:point];
    }
    
    // 设置曝光
    if ([captureDevice isExposureModeSupported:AVCaptureExposureModeAutoExpose]) {
        [captureDevice setExposureMode:AVCaptureExposureModeAutoExpose];
    }
    if ([captureDevice isExposurePointOfInterestSupported]) {
        [captureDevice setExposurePointOfInterest:point];
    }
    // 解锁配置
    [captureDevice unlockForConfiguration];
}

//// 压缩视频
//
//-(void)compressVideoWithUrl:(NSURL *)url compressionType:(NSString *)type filePath:(void(^)(NSString *resultPath,float memorySize,NSString * videoImagePath,int seconds))resultBlock {
//
//
//
//    NSString *resultPath;
//
//
//
//
//
//    // 视频压缩前大小
//
//    NSData *data = [NSDatadataWithContentsOfURL:url];
//
//    CGFloat totalSize = (float)data.length /1024 / 1024;
//
//    NSLog(@"压缩前大小：%.2fM",totalSize);
//
//    AVURLAsset *avAsset = [AVURLAssetURLAssetWithURL:urloptions:nil];
//
//
//
//    CMTime time = [avAssetduration];
//
//
//
//    // 视频时长
//
//    int seconds =ceil(time.value / time.timescale);
//
//
//
//    NSArray *compatiblePresets = [AVAssetExportSession exportPresetsCompatibleWithAsset:avAsset];
//
//    if ([compatiblePresets containsObject:type]) {
//
//
//
//        // 中等质量
//
//        AVAssetExportSession *session = [[AVAssetExportSession alloc]initWithAsset:avAssetpresetName:AVAssetExportPresetMediumQuality];
//
//
//
//        // 用时间给文件命名防止存储被覆盖
//
//        NSDateFormatter *formatter = [[NSDateFormatter alloc]init];
//
//        [formatter setDateFormat:@"yyyy-MM-dd-HH:mm:ss"];
//
//
//
//        // 若压缩路径不存在重新创建
//
//        NSFileManager *manager = [NSFileManager defaultManager];
//
//        BOOL isExist = [manager fileExistsAtPath:COMPRESSEDVIDEOPATH];
//
//        if (!isExist) {
//
//            [manager createDirectoryAtPath:COMPRESSEDVIDEOPATH withIntermediate Directories:YES attributes:nilerror:nil];
//
//        }
//
//        resultPath = [COMPRESSEDVIDEOPATHstringByAppendingPathComponent:[NSStringstringWithFormat:@"user%outputVideo-%@.mp4",arc4random_uniform(10000),[formatterstringFromDate:[NSDatedate]]]];
//
//
//
//        session.outputURL = [NSURL fileURLWithPath:resultPath];
//
//        session.outputFileType =AVFileTypeMPEG4;
//
//        session.shouldOptimizeForNetworkUse =YES;
//
//        [session exportAsynchronouslyWithCompletionHandler:^{
//
//
//
//            switch (session.status) {
//
//                caseAVAssetExportSessionStatusUnknown:
//
//                    break;
//
//                caseAVAssetExportSessionStatusWaiting:
//
//                    break;
//
//                caseAVAssetExportSessionStatusExporting:
//
//                    break;
//
//                caseAVAssetExportSessionStatusCancelled:
//
//                    break;
//
//                caseAVAssetExportSessionStatusFailed:
//
//                    break;
//
//                caseAVAssetExportSessionStatusCompleted:{
//
//
//
//                    NSData *data = [NSDatadataWithContentsOfFile:resultPath];
//
//                    // 压缩过后的大小
//
//                    float compressedSize = (float)data.length /1024 / 1024;
//
//                    resultBlock(resultPath,compressedSize,@"",seconds);
//
//                    NSLog(@"压缩后大小：%.2f",compressedSize);
//
//                }
//
//                default:
//
//                    break;
//
//            }
//
//        }];
//
//    }
//
//}
#pragma mark -SET/GET
- (GPUImageView *)filteredVideoView {
    if (!_filteredVideoView) {
        _filteredVideoView = [[GPUImageView alloc]initWithFrame:self.view.bounds];
        _filteredVideoView.fillMode = kGPUImageFillModePreserveAspectRatioAndFill;
        _filteredVideoView.clipsToBounds = YES;
    }
    return _filteredVideoView;
}
- (UIImageView *)imageView {
    if (!_imageView) {
        _imageView = [[UIImageView alloc]initWithFrame:self.view.bounds];
    }
    return _imageView;
}
- (GPUImageVideoCamera *)videoCamera {
    if (!_videoCamera) {
        Class class;
        if (self.optionSegument.selectedSegmentIndex == 0) {
            class = [JKGPUImageVideoCamera class];
        }else {
            class = [GPUImageStillCamera class];
        }
        _videoCamera = [[class alloc]initWithSessionPreset:AVCaptureSessionPreset1280x720 cameraPosition:AVCaptureDevicePositionBack];
        _videoCamera.outputImageOrientation = UIInterfaceOrientationPortrait;
        [_videoCamera addAudioInputsAndOutputs];
    }
    return _videoCamera;
}
- (GPUImageFilter *)alphaFilter {
    if (!_alphaFilter) {
        _alphaFilter = [[GPUImageOpacityFilter alloc] init];
    }
    return _alphaFilter;
}

-(GPUImageUIElement *)element {
    if (!_element) {
        UIView *view = [[UIView alloc]initWithFrame:self.view.bounds];;
        view.backgroundColor = [UIColor clearColor];
        UILabel *label = [UILabel new];
        label.text = @"这是水印";
        label.font = [UIFont systemFontOfSize:15];
        [label sizeToFit];
        CGFloat height = CGRectGetHeight(label.frame);
        CGFloat width = CGRectGetWidth(label.frame);
        label.frame = CGRectMake([UIScreen mainScreen].bounds.size.width-width, [UIScreen mainScreen].bounds.size.height-height, width, height);
        [view addSubview:label];
        _element = [[GPUImageUIElement alloc]initWithView:view];
    }
    return _element;
}

@end
