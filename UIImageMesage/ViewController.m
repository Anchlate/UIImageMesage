//
//  ViewController.m
//  UIImageMesage
//
//  Created by Qianrun on 16/7/22.
//  Copyright © 2016年 qianrun. All rights reserved.
//

#import "ViewController.h"

#import <Photos/Photos.h>
#import <CoreLocation/CoreLocation.h>

#define iOS8 ([[[[UIDevice currentDevice] systemVersion] substringToIndex:1] intValue]>=8)

@interface ViewController ()<UIImagePickerControllerDelegate, UINavigationControllerDelegate, CLLocationManagerDelegate>

- (IBAction)selectImage:(id)sender;
@property (strong, nonatomic) IBOutlet UIImageView *imageView;


@property (nonatomic, strong) CLLocationManager *locationManager;
@property (nonatomic, copy) NSDictionary *gpsDict;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
}

#pragma mark 保存照片成功后回调
- (void)image:(UIImage*)image didFinishSavingWithError:(NSError*)error contextInfo:(void*)contextInfo{
    if (!error) {
        
        NSLog(@"picture saved with no error.");
        self.imageView.image = image;
        
    } else {
        
        NSLog(@"error occured while saving the picture%@", error);
        
    }
}

#pragma mark 成功获得相片还是视频后的回调
- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info{
    
    [picker dismissViewControllerAnimated:YES completion:nil];
    
    if (picker.sourceType == UIImagePickerControllerSourceTypeCamera) {
        
        // 1. 获取EXIF等信息
        NSDictionary *metadata = [info valueForKey:UIImagePickerControllerMediaMetadata];
        NSMutableDictionary *mutableDict = [NSMutableDictionary dictionaryWithDictionary:metadata];
        
        if (metadata&& self.gpsDict) {
            [mutableDict setValue:self.gpsDict forKey:(NSString*)kCGImagePropertyGPSDictionary];
        }
        
        UIImage *image = [info objectForKey:UIImagePickerControllerOriginalImage];
//        image = [UIImage imageWithCGImage:[image CGImage] scale:0 orientation:0];
        
//        UIImage *image = [self fixOrientation:[info objectForKey:UIImagePickerControllerOriginalImage]];
//        NSLog(@"......:%ld", image.imageOrientation);
        
        
        // 2. 压缩并写入EXIF信息
//        self.imageView.image = image;
        self.imageView.image = [self imageByScalingNotCroppingForSize:image toSize:CGSizeMake(100, 100) message:mutableDict];
        
    } else if (picker.sourceType == UIImagePickerControllerSourceTypePhotoLibrary) {
        
        //获取图片的NSURL 来源于AssetsLibrary.framework  #import <AssetsLibrary/AssetsLibrary.h>
        NSURL *url = [info objectForKey:UIImagePickerControllerReferenceURL];
        
        NSLog(@"......sdfsdfsdfdsfdsfffffff:%@", url);
        
        PHFetchResult *asset1 = [PHAsset fetchAssetsWithALAssetURLs:@[url] options:nil];
        [[PHImageManager defaultManager] requestImageDataForAsset:asset1[0] options:nil resultHandler:^(NSData * _Nullable imageData, NSString * _Nullable dataUTI, UIImageOrientation orientation, NSDictionary * _Nullable info) {

            NSLog(@"......bbbbb:%@", info);
            CGImageSourceRef imgSource = CGImageSourceCreateWithData((CFDataRef)imageData, nil);
            CFDictionaryRef imageInfo = CGImageSourceCopyPropertiesAtIndex(imgSource, 0, NULL);
            
            UIImage *image = [UIImage imageWithData:imageData];
            
            self.imageView.image = [self imageByScalingNotCroppingForSize:image toSize:CGSizeMake(100, 100) message:(__bridge NSDictionary *)imageInfo];
            
        }];
        
    }
}

- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker{
    
    [picker dismissViewControllerAnimated:YES completion:nil];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    
}

//- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
//{
//    return (interfaceOrientation == UIInterfaceOrientationPortrait);
//}

- (IBAction)selectImage:(id)sender {
    
    [self.locationManager startUpdatingLocation];
    
    // 1.
    __block UIImagePickerController *imagePickerController = [[UIImagePickerController alloc] init];
    imagePickerController.delegate = self;
    imagePickerController.allowsEditing = YES;
    
    typeof(self) weakSelf = self;
    
    // 2.
    UIAlertController* alert = [UIAlertController alertControllerWithTitle:@"提 示"
                                                                   message:@"获 取 图 片 方 式."
                                                            preferredStyle:UIAlertControllerStyleActionSheet];
    
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad) {
        //activity.popoverPresentationController.sourceView = shareButtonBarItem;
        
        alert.popoverPresentationController.barButtonItem = [[UIBarButtonItem alloc]initWithCustomView:[[UIView alloc]init]];
        
    }
    
    
    // 3.
    UIAlertAction* defaultAction = [UIAlertAction actionWithTitle:@"从相册获取" style:UIAlertActionStyleDefault
                                                          handler:^(UIAlertAction * action) {
                                                              
                                                              NSLog(@"...从相册选择");
                                                              imagePickerController.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
                                                              [weakSelf presentViewController:imagePickerController animated:YES completion:nil];
                                                          }];
    
    
    
    UIAlertAction* defaultAction1 = [UIAlertAction actionWithTitle:@"拍照" style:UIAlertActionStyleDefault
                                                           handler:^(UIAlertAction * action) {
                                                               
                                                               NSLog(@"...从相机选择");
                                                               imagePickerController.sourceType = UIImagePickerControllerSourceTypeCamera;
                                                               [weakSelf presentViewController:imagePickerController animated:YES completion:nil];
                                                               
                                                           }];
    
    
    
    
    UIAlertAction *action = [UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
    }];
    
    [alert addAction:action];
    
    // 4. 判断是否支持相机
    if([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera]) {
        
        [alert addAction:defaultAction];
        [alert addAction:defaultAction1];
        
    } else {
        
        [alert addAction:defaultAction];
        
    }
    
    // 5.
    alert.preferredAction = action; // 强调作用，有连接key board时按enter触发
    [self presentViewController:alert animated:YES completion:nil];
    
}

#pragma mark -CLLocationManagerDelegate
-(void)locationManager:(CLLocationManager *)manager didFailWithError:(NSError *)error {
    //定位失败，作相应处理。
}

-(void)locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray *)locations {
    
    CLLocation *newLocation = locations[0];
    [manager stopUpdatingLocation];//取到定位即可停止刷新，没有必要一直刷新，耗电。
    
    NSTimeZone    *timeZone   = [NSTimeZone timeZoneWithName:@"UTC"];
    NSDateFormatter *formatter  = [[NSDateFormatter alloc] init];
    [formatter setTimeZone:timeZone];
    [formatter setDateFormat:@"HH:mm:ss.SS"];
    
    NSDictionary *gpsDict   = [NSDictionary dictionaryWithObjectsAndKeys:
                               [NSNumber numberWithFloat:fabs(newLocation.coordinate.latitude)], kCGImagePropertyGPSLatitude,
                               ((newLocation.coordinate.latitude >= 0) ? @"N" : @"S"), kCGImagePropertyGPSLatitudeRef,
                               [NSNumber numberWithFloat:fabs(newLocation.coordinate.longitude)], kCGImagePropertyGPSLongitude,
                               ((newLocation.coordinate.longitude >= 0) ? @"E" : @"W"), kCGImagePropertyGPSLongitudeRef,
                               [formatter stringFromDate:[newLocation timestamp]], kCGImagePropertyGPSTimeStamp,
                               nil];
    
    self.gpsDict = gpsDict;
}

#pragma mark -Private
// 调整照相机照片旋转的方法
- (UIImage *)fixOrientation:(UIImage *)aImage {
    // No-op if the orientation is already correct
    if (aImage.imageOrientation == UIImageOrientationUp)
        return aImage;
    
    // We need to calculate the proper transformation to make the image upright.
    // We do it in 2 steps: Rotate if Left/Right/Down, and then flip if Mirrored.
    CGAffineTransform transform = CGAffineTransformIdentity;
    
    switch (aImage.imageOrientation) {
        case UIImageOrientationDown:
        case UIImageOrientationDownMirrored:
            transform = CGAffineTransformTranslate(transform, aImage.size.width, aImage.size.height);
            transform = CGAffineTransformRotate(transform, M_PI);
            break;
            
        case UIImageOrientationLeft:
        case UIImageOrientationLeftMirrored:
            transform = CGAffineTransformTranslate(transform, aImage.size.width, 0);
            transform = CGAffineTransformRotate(transform, M_PI_2);
            break;
            
        case UIImageOrientationRight:
        case UIImageOrientationRightMirrored:
            transform = CGAffineTransformTranslate(transform, 0, aImage.size.height);
            transform = CGAffineTransformRotate(transform, -M_PI_2);
            break;
        default:
            break;
    }
    
    switch (aImage.imageOrientation) {
        case UIImageOrientationUpMirrored:
        case UIImageOrientationDownMirrored:
            transform = CGAffineTransformTranslate(transform, aImage.size.width, 0);
            transform = CGAffineTransformScale(transform, -1, 1);
            break;
            
        case UIImageOrientationLeftMirrored:
        case UIImageOrientationRightMirrored:
            transform = CGAffineTransformTranslate(transform, aImage.size.height, 0);
            transform = CGAffineTransformScale(transform, -1, 1);
            break;
        default:
            break;
    }
    
    // Now we draw the underlying CGImage into a new context, applying the transform
    // calculated above.
    CGContextRef ctx = CGBitmapContextCreate(NULL, aImage.size.width, aImage.size.height,
                                             CGImageGetBitsPerComponent(aImage.CGImage), 0,
                                             CGImageGetColorSpace(aImage.CGImage),
                                             CGImageGetBitmapInfo(aImage.CGImage));
    CGContextConcatCTM(ctx, transform);
    switch (aImage.imageOrientation) {
        case UIImageOrientationLeft:
        case UIImageOrientationLeftMirrored:
        case UIImageOrientationRight:
        case UIImageOrientationRightMirrored:
            // Grr...
            CGContextDrawImage(ctx, CGRectMake(0,0,aImage.size.height,aImage.size.width), aImage.CGImage);
            break;
            
        default:
            CGContextDrawImage(ctx, CGRectMake(0,0,aImage.size.width,aImage.size.height), aImage.CGImage);
            break;
    }
    
    // And now we just create a new UIImage from the drawing context
    CGImageRef cgimg = CGBitmapContextCreateImage(ctx);
    UIImage *img = [UIImage imageWithCGImage:cgimg];
    CGContextRelease(ctx);
    CGImageRelease(cgimg);
    return img;
}

#pragma mark -Getter

-(CLLocationManager *)locationManager
{
    if (_locationManager == nil) {
        _locationManager = [[CLLocationManager alloc] init];
        // 设置定位精度
        [_locationManager setDesiredAccuracy:kCLLocationAccuracyNearestTenMeters];
        _locationManager.delegate = self;
        
        if (iOS8) {//ios8.0以上版本CLLocationManager定位服务需要授权
            [_locationManager requestWhenInUseAuthorization];
        }
    }
    return _locationManager;
}

- (UIImage*)imageByScalingNotCroppingForSize:(UIImage*)anImage toSize:(CGSize)frameSize message:(NSDictionary *)message
{
    UIImage* sourceImage = anImage;
    UIImage* newImage = nil;
    CGSize imageSize = sourceImage.size;
    CGFloat width = imageSize.width;
    CGFloat height = imageSize.height;
    CGFloat targetWidth = frameSize.width;
    CGFloat targetHeight = frameSize.height;
    CGFloat scaleFactor = 0.0;
    CGSize scaledSize = frameSize;
    
    if (CGSizeEqualToSize(imageSize, frameSize) == NO) {
        CGFloat widthFactor = targetWidth / width;
        CGFloat heightFactor = targetHeight / height;
        
        // opposite comparison to imageByScalingAndCroppingForSize in order to contain the image within the given bounds
        if (widthFactor == 0.0) {
            scaleFactor = heightFactor;
        } else if (heightFactor == 0.0) {
            scaleFactor = widthFactor;
        } else if (widthFactor > heightFactor) {
            scaleFactor = heightFactor; // scale to fit height
        } else {
            scaleFactor = widthFactor; // scale to fit width
        }
        scaledSize = CGSizeMake(width * scaleFactor, height * scaleFactor);
    }
    
    UIGraphicsBeginImageContext(scaledSize); // this will resize
    
    [sourceImage drawInRect:CGRectMake(0, 0, scaledSize.width, scaledSize.height)];
    
    newImage = UIGraphicsGetImageFromCurrentImageContext();
    if (newImage == nil) {
        NSLog(@"could not scale image");
    }
    
    // pop the context to get back to the default
    UIGraphicsEndImageContext();
    
//    newImage = [UIImage imageWithCGImage:[newImage CGImage] scale:1 orientation:0];
    
    NSData *imageNSData = UIImagePNGRepresentation(newImage);
    
    if (!imageNSData) {
        imageNSData = UIImageJPEGRepresentation(newImage, 1.0);
    }
    
    CGImageSourceRef imgSource = CGImageSourceCreateWithData((__bridge_retained CFDataRef)imageNSData, NULL);
    
    NSMutableData *dest_data = [NSMutableData data];
    CFStringRef UTI = CGImageSourceGetType(imgSource);
    CGImageDestinationRef destination = CGImageDestinationCreateWithData((__bridge CFMutableDataRef)dest_data, UTI, 1,NULL);
    CGImageDestinationAddImageFromSource(destination, imgSource, 0, (__bridge CFDictionaryRef)message);
    CGImageDestinationFinalize(destination);
    CFRelease(imgSource);
    CFRelease(destination);
    
    CIImage *ciimage = [CIImage imageWithData:dest_data];
    NSDictionary *dict = [ciimage properties];
    NSLog(@"......;%@", dict);
    
    
    return [UIImage imageWithData: dest_data];
    
//    UIImage *img = [UIImage imageWithCGImage:[[UIImage imageWithData:dest_data] CGImage] scale:1 orientation:0];
//    NSLog(@"......:%ld", img.imageOrientation);
//    
//    return img;
}

@end