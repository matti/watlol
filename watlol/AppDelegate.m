//
//  AppDelegate.m
//  watlol
//
//  Created by mpa on 25/06/2017.
//  Copyright © 2017 mpa. All rights reserved.
//

#import "AppDelegate.h"
@import CoreBluetooth;
@import KeenClient;
@import AVFoundation;
#import <ImageIO/CGImageProperties.h>

@interface AppDelegate ()

@end

@implementation MovingAverage
-(id)initWithSize:(int)s {
    if (self = [super init]) {
        samples = [[NSMutableArray alloc] initWithCapacity:s];
        size = s;
    }
    return self;
}
-(void)addSample:(float)sample {
    if ([samples count] > size) {
        [samples removeObjectAtIndex:0];
    }
    [samples addObject:[NSNumber numberWithFloat:sample]];
}

-(NSMutableArray*) samples {
    return samples;
}

-(float)movingAverage {
    return 0;
}

-(float)changeRate {
    NSNumber *latestNumber = [samples lastObject];
    NSNumber *firstNumber = [samples firstObject];
    
    return ([latestNumber floatValue] - [firstNumber floatValue]);
}
@end


@implementation AppDelegate
CBCentralManager *cbCentralManager;
AVCaptureStillImageOutput *stillImageOutput;
AVCaptureSession *captureSession;

MovingAverage *avg8periods;
MovingAverage *avg26periods;
MovingAverage *avg76periods;

float lastBeanTemp;
float lastFirstTemp;
float lastSecondTemp;

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {

    cbCentralManager = [[CBCentralManager alloc] initWithDelegate:self queue: dispatch_get_main_queue()];
    
    [KeenClient sharedClientWithProjectID:@"596788dfc9e77c00015d95c6" andWriteKey:@"FABAED949EA97B1176795E759EB34DE5F33859CEDA77BD87935593DE1C6F983D2E606BF734B82DD06CB21F1E23372873CFF3960DC04B6EB8C2F378AA55530B121F61B52E8D7F1FE0E5D3F80A87BC52D6D014793301209BDAF2A83C5A93E1273B" andReadKey: nil];

    [[ KeenClient sharedClient ] setMaxEventUploadAttempts: 1569325000];

    [ self updateTime ];
    
    //[ self startCaptureSession ];
    
    avg8periods = [[MovingAverage alloc] initWithSize:8];
    avg26periods = [[MovingAverage alloc] initWithSize:26];
    avg76periods = [[MovingAverage alloc] initWithSize:76];
    

    return YES;
}

-(void)startCaptureSession {
    captureSession = [[AVCaptureSession alloc] init];
    captureSession.sessionPreset = AVCaptureSessionPresetLow;
    
    AVCaptureDevice *device = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
    
    NSError *error = nil;
    AVCaptureDeviceInput *input = [AVCaptureDeviceInput deviceInputWithDevice:device error:&error];
    if (!input) {
        // Handle the error appropriately.
        NSLog(@"ERROR: trying to open camera: %@", error);
    }
    [captureSession addInput:input];

    stillImageOutput = [[AVCaptureStillImageOutput alloc] init];
    NSDictionary *outputSettings = [[NSDictionary alloc] initWithObjectsAndKeys: AVVideoCodecJPEG, AVVideoCodecKey, nil];
    [stillImageOutput setOutputSettings:outputSettings];
    [captureSession addOutput:stillImageOutput];
    
    [captureSession startRunning];
}

-(void) snapPhoto {
    AVCaptureConnection *videoConnection = nil;
    for (AVCaptureConnection *connection in stillImageOutput.connections)
    {
        for (AVCaptureInputPort *port in [connection inputPorts])
        {
            if ([[port mediaType] isEqual:AVMediaTypeVideo] )
            {
                videoConnection = connection;
                break;
            }
        }
        if (videoConnection)
        {
            break;
        }
    }
    
    NSLog(@"about to request a capture from: %@", stillImageOutput);
    
    [stillImageOutput captureStillImageAsynchronouslyFromConnection:videoConnection completionHandler: ^(CMSampleBufferRef imageSampleBuffer, NSError *error)
     {
         CFDictionaryRef exifAttachments = CMGetAttachment( imageSampleBuffer, kCGImagePropertyExifDictionary, NULL);
         if (exifAttachments)
         {
             // Do something with the attachments.
             NSLog(@"attachements: %@", exifAttachments);
         } else {
             NSLog(@"no attachments");
         }
         
         NSData *imageData = [AVCaptureStillImageOutput jpegStillImageNSDataRepresentation:imageSampleBuffer];
         UIImage *image = [[UIImage alloc] initWithData:imageData];
         
         UIImageWriteToSavedPhotosAlbum(image, nil, nil, nil);
     }];
}

-(void)updateTime {
    NSDate *currentDateAndTime = [NSDate date];
    NSDateFormatter *timeFormat = [[NSDateFormatter alloc] init];
    [timeFormat setDateFormat:@"HH:mm:ss"];
    NSDateFormatter *dateFormat = [[NSDateFormatter alloc] init];
    [dateFormat setDateFormat:@"dd.MM.yyyy (ccc)"];
    
    NSString *timeString = [timeFormat stringFromDate:currentDateAndTime];
    NSString *dateString = [dateFormat stringFromDate:currentDateAndTime];
    
    UIViewController* mainController = (UIViewController*)  self.window.rootViewController;
    
    for (id v in mainController.view.subviews) {
        UILabel *label = v;
        
        if ([[v accessibilityLabel] isEqualToString: @"aika"]) {
            [label setText: timeString];
        }
        
        if ([[v accessibilityLabel] isEqualToString: @"pvm"]) {
            [label setText: dateString];
        }
    }

    
    NSInteger hour = 0;
    NSInteger minute = 0;
    NSCalendar *currentCalendar = [NSCalendar currentCalendar];
    [currentCalendar getHour:&hour minute:&minute second:NULL nanosecond:NULL fromDate:currentDateAndTime];

    if ( hour >= 21 || hour < 8) {
        [[UIScreen mainScreen] setBrightness:0.0];
    } else {
        [[UIScreen mainScreen] setBrightness:1.0];
    }

    [self performSelector:@selector(updateTime) withObject:nil afterDelay:1];
}

-(void)showAlert: (NSString*) message {
    UIAlertController *objAlertController = [UIAlertController alertControllerWithTitle:@"Alert" message:message preferredStyle:UIAlertControllerStyleAlert];
    
    UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:@"OK"
                                                           style:UIAlertActionStyleCancel handler:^(UIAlertAction *action) {
                                                               NSLog(@"Ok clicked!");
                                                           }];
    
    [objAlertController addAction:cancelAction];
    
    [[[[[UIApplication sharedApplication] windows] objectAtIndex:0] rootViewController] presentViewController:objAlertController animated:YES completion:^{
        [objAlertController dismissViewControllerAnimated:YES completion:nil];
    }];
    
    
}


-(void)centralManagerDidUpdateState:(CBCentralManager *)central {
    if (central.state == CBManagerStatePoweredOn ){
        [self startScan ];
    } else {
        NSLog(@"bluetooth not on");
    }
    
}

-(void) restartScan: (NSInteger) delay {
    [cbCentralManager stopScan ];
    NSLog(@"Stopped scanning");

    [self performSelector:@selector(startScan) withObject:nil afterDelay:delay];
    NSLog(@"Will start scanning in %d s", delay);
}

-(void) startScan {
    NSDictionary *options = [NSDictionary dictionaryWithObjectsAndKeys:
                             [NSNumber numberWithBool:YES], CBCentralManagerScanOptionAllowDuplicatesKey,
                             nil];
    
    [ cbCentralManager scanForPeripheralsWithServices:nil options:options ];
    
    // maybefix: if hangs -- was prob the antenna
    //[self performSelector:@selector(startScan) withObject:nil afterDelay:360];
    
    NSLog(@"Started scanning");
}

- (int)getWordFromBuffer:(const unsigned char *)bytes atOffset:(int) offset
{
    return (int)bytes[offset] | (bytes[offset+1] << 8);
}

-(void)centralManager:(CBCentralManager *)central didDiscoverPeripheral:(CBPeripheral *)peripheral advertisementData:(NSDictionary<NSString *,id> *)advertisementData RSSI:(NSNumber *)RSSI {

    // first discovery is always (?) cached, then subsequent update is usually up-to-date.
    //NSLog(@"BT discovered %@ (%@)", peripheralName, RSSI);
    //    NSArray *components = [peripheralName componentsSeparatedByString:@"/"];
    //    batteryLevel = [components[1] floatValue];
    //    beanTemp = [components[2] floatValue];
    //    firstTemp = [components[3] floatValue];
    //    secondTemp = [components[4] floatValue];
    
    UIViewController* mainController = (UIViewController*)  self.window.rootViewController;
    NSString *peripheralName = [peripheral name];
    
    NSData *manufacturerData = [advertisementData objectForKey: CBAdvertisementDataManufacturerDataKey ];
    int dataLength = manufacturerData.length;
    
    int batteryPercentage = -1;
    int batteryVoltage = -1;
    float beanTemp = -1;
    float firstTemp = -1;
    float secondTemp = -1;

    if (dataLength > 0) {
        NSData *manufacturerIdData = [manufacturerData subdataWithRange:NSMakeRange(0, 1)];
        int manufacturerId = *(int*)([manufacturerIdData bytes]);
        NSLog(@"manufacturerId: %d", manufacturerId);
        
        if (manufacturerId != 99) {
            return;
        }
        
        for (int i=1; i<dataLength; i++) {
            NSData *data = [manufacturerData subdataWithRange:NSMakeRange(i, 1)];
            int value = *(int*)([data bytes]);
            NSLog(@"%d: %d", i, value);
    
//1            customAdvertData[6] = BUILD_NUMBER;
//2            customAdvertData[7] = batteryVoltage;
//3            customAdvertData[8] = batteryPercentage;
//4            customAdvertData[9] = (int) tempBean;
//5            customAdvertData[10] = (int) tempFirstSig;
//6            customAdvertData[11] = (int) (tempFirstMantissa * 10);
//7            customAdvertData[12] = (int) tempSecondSig;
//8            customAdvertData[13] = (int) (tempSecondMantissa * 10);

            switch (i) {
                case 1:
                    // build number;
                    break;
                case 2:
                    batteryVoltage = value * 10;
                    break;
                case 3:
                    batteryPercentage = value * 10;
                    break;
                case 4:
                    beanTemp = 1.0 * value;
                    break;
                case 5:
                    firstTemp = value;
                    break;
                case 6:
                    firstTemp = firstTemp + (value / 10.0);
                    break;
                case 7:
                    secondTemp = value;
                    break;
                case 8:
                    secondTemp = secondTemp + (value / 10.0);
                    break;
                default:
                    break;
            }
        }
    } else {
        return;
    }
    
    [avg8periods addSample:secondTemp];
    [avg26periods addSample:secondTemp];
    [avg76periods addSample:secondTemp];
    
    NSDate *currentDateAndTime = [NSDate date];
    NSDateFormatter *timeFormat = [[NSDateFormatter alloc] init];
    [timeFormat setDateFormat:@"HH:mm:ss"];
    NSString *timeString = [timeFormat stringFromDate:currentDateAndTime];
    
    for (id v in mainController.view.subviews) {
        UILabel *label = v;

        if ([[v accessibilityLabel] isEqualToString: @"akku"]) {
            [label setText: [NSString stringWithFormat:@"%d%%", batteryPercentage]];
        }
        if ([[v accessibilityLabel] isEqualToString: @"jännite"]) {
            [label setText: [NSString stringWithFormat:@"%d", batteryVoltage]];
        }
        if ([[v accessibilityLabel] isEqualToString: @"rssi"]) {
            [label setText: [RSSI stringValue]];
        }
        if ([[v accessibilityLabel] isEqualToString: @"ilma"]) {
            [label setText: [NSString stringWithFormat:@"%.01f", beanTemp]];
        }
        if ([[v accessibilityLabel] isEqualToString: @"vesi"]) {
            [label setText: [NSString stringWithFormat:@"%.01f", firstTemp]];
        }
        if ([[v accessibilityLabel] isEqualToString: @"sauna"]) {
            [label setText: [NSString stringWithFormat:@"%.01f", secondTemp]];
        }
        if ([[v accessibilityLabel] isEqualToString: @"päivitys"]) {
            [label setText: timeString];
        }
        
        if ([[v accessibilityLabel] isEqualToString: @"saunamoving"]) {
            NSString *direction5 = @"";
            NSString *direction30 = @"";
            NSString *direction60 = @"";
            
            float changeRate5 = [avg8periods changeRate];
            float changeRate20 = [avg26periods changeRate];
            float changeRate60 = [avg76periods changeRate];
            
            if (changeRate5 >= 0) { direction5 = @"+"; }
            if (changeRate20 >= 0) { direction30 = @"+"; }
            if (changeRate60 >= 0) { direction60 = @"+"; }
            
            [label setText: [NSString stringWithFormat:@"(%@%.01f, %@%.01f, %@%.01f)", direction5, changeRate5, direction30, changeRate20, direction60, changeRate60]];
        }
    }
    
    if (
        true == false &&                        //TODO: enable
        lastBeanTemp == beanTemp &&
        lastFirstTemp == firstTemp &&
        lastSecondTemp == secondTemp
        ) {
    } else {
        lastBeanTemp = beanTemp;
        lastFirstTemp = firstTemp;
        lastSecondTemp = secondTemp;
    
        NSDictionary *event = [NSDictionary dictionaryWithObjectsAndKeys:
                               [NSNumber numberWithInt: batteryPercentage], @"batteryLevel",
                               [NSNumber numberWithFloat: beanTemp], @"beanTemp",
                               [NSNumber numberWithFloat: firstTemp], @"firstTemp",
                               [NSNumber numberWithFloat: secondTemp], @"secondTemp",
                               nil];
    
        [[KeenClient sharedClient] addEvent:event toEventCollection:@"temps" error:nil];
        [[KeenClient sharedClient] uploadWithFinishedBlock:nil ];
    
        NSLog(@"Sent to keen");
    }
    
    // maybe slows down updates..?
    //[self snapPhoto ];
    
    [self restartScan:30 ];
}

-(void)centralManager:(CBCentralManager *)central didDisconnectPeripheral:(CBPeripheral *)peripheral error:(NSError *)error {
}

- (void)applicationWillResignActive:(UIApplication *)application {
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and invalidate graphics rendering callbacks. Games should use this method to pause the game.
}


- (void)applicationDidEnterBackground:(UIApplication *)application {
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
}


- (void)applicationWillEnterForeground:(UIApplication *)application {
    // Called as part of the transition from the background to the active state; here you can undo many of the changes made on entering the background.
}


- (void)applicationDidBecomeActive:(UIApplication *)application {
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}


- (void)applicationWillTerminate:(UIApplication *)application {
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}


@end
