//
//  ViewController.m
//  SceneKitCamera
//
//  Created by arplanet on 2017/11/7.
//  Copyright © 2017年 Johnny. All rights reserved.
//

#import "ViewController.h"

@interface ViewController ()<AVCaptureVideoDataOutputSampleBufferDelegate>{
    NSString *_sessionPresent;
}

@property(nonatomic)AVCaptureSession *avSession;
@property(nonatomic)AVCaptureInput *avVideoDeviceInput;
@property(nonatomic)AVCaptureDevice * avVideoDevice;
@property(nonatomic)AVCaptureVideoDataOutput *avVideoDataOutput;

@property(nonatomic)AVCaptureVideoPreviewLayer *avVideoPreviewLayer;


@end

@implementation ViewController
-(void)autoLayout{
    self.cameraView = [[UIImageView alloc] initWithFrame:[UIScreen mainScreen].bounds];
    [self.view addSubview:self.cameraView];
}
- (AVCaptureDevice *)deviceWithPostion:(AVCaptureDevicePosition)position
{
    NSArray *devices = [AVCaptureDevice devicesWithMediaType:AVMediaTypeVideo];
    for (AVCaptureDevice *device in devices) {
        if (device.position == position) {
            return device;
        }
    }
    return nil;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    [self autoLayout];
    NSLog(@"Start");
    _sessionPresent = AVCaptureSessionPreset640x480;
    
    self.avSession = [[AVCaptureSession alloc] init];
    [self.avSession setSessionPreset:_sessionPresent];
    [self.avSession beginConfiguration];
    
//     self.avVideoPreviewLayer = [[AVCaptureVideoPreviewLayer alloc] initWithSession:self.avSession];
//    self.avVideoPreviewLayer.frame = [UIScreen mainScreen].bounds;
//    [self.view.layer addSublayer:self.avVideoPreviewLayer];
    
    if (@available(iOS 10.0, *)) {
        self.avVideoDevice = [AVCaptureDevice defaultDeviceWithDeviceType:AVCaptureDeviceTypeBuiltInWideAngleCamera mediaType:AVMediaTypeVideo position:AVCaptureDevicePositionBack];
    } else {
        self.avVideoDevice = [self deviceWithPostion:AVCaptureDevicePositionBack];
    }
    if(self.avVideoDevice == nil)
        assert(0);
    
    NSError *error;
    self.avVideoDeviceInput = [AVCaptureDeviceInput deviceInputWithDevice:self.avVideoDevice error:&error];
    
    self.avVideoDataOutput = [[AVCaptureVideoDataOutput alloc] init];
    [self.avVideoDataOutput setAlwaysDiscardsLateVideoFrames:YES];
    [self.avVideoDataOutput setVideoSettings:[NSDictionary dictionaryWithObject:[NSNumber numberWithInt:kCVPixelFormatType_32BGRA] forKey:(id)kCVPixelBufferPixelFormatTypeKey]];
    dispatch_queue_t outputQueue = dispatch_queue_create("com.video.queue", NULL);
    [self.avVideoDataOutput setSampleBufferDelegate:self queue:outputQueue];
    
    AVCaptureConnection *avConnection = [self.avVideoDataOutput connectionWithMediaType:AVMediaTypeVideo];
    [avConnection setVideoOrientation:AVCaptureVideoOrientationPortrait];
    
    [self.avSession addInput:self.avVideoDeviceInput];
    [self.avSession addOutput:self.avVideoDataOutput];
    [self.avSession commitConfiguration];
    
    [self.avSession startRunning];
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}
#pragma mark- AVCaptureVideoDataOutputSampleBufferDelegate
-(void)captureOutput:(AVCaptureOutput *)output didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer fromConnection:(AVCaptureConnection *)connection{
    UIImage *img = [self imageFromSampleBuffer:sampleBuffer];
    dispatch_sync(dispatch_get_main_queue(), ^{
        [self.cameraView setImage:img];
    });
}

-(UIImage *)imageFromSampleBuffer:(CMSampleBufferRef)sampleBuffer{
    CVPixelBufferRef pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer);
    CFDictionaryRef attachments = CMCopyDictionaryOfAttachments(kCFAllocatorDefault, sampleBuffer, kCMAttachmentMode_ShouldPropagate);
    CIImage *ciImage = [[CIImage alloc] initWithCVPixelBuffer:pixelBuffer
                                                      options:(__bridge NSDictionary *)attachments];
    if (attachments) {
        CFRelease(attachments);
    }
    // fixing the orientation of the CIImage
    UIInterfaceOrientation curOrientation = [[UIApplication sharedApplication] statusBarOrientation];
    
    if (curOrientation == UIInterfaceOrientationLandscapeLeft){
        ciImage = [ciImage imageByApplyingOrientation:3];
    } else if (curOrientation == UIInterfaceOrientationLandscapeRight){
        ciImage = [ciImage imageByApplyingOrientation:1];
    } else if (curOrientation == UIInterfaceOrientationPortrait){
        ciImage = [ciImage imageByApplyingOrientation:6];
    } else if (curOrientation == UIInterfaceOrientationPortraitUpsideDown){
        ciImage = [ciImage imageByApplyingOrientation:8];
    }
    UIImage *image = [UIImage imageWithCIImage:ciImage];
    return (image);
}

@end
