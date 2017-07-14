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


@interface AppDelegate ()

@end

@implementation AppDelegate
CBCentralManager *cbCentralManager;
float lastBeanTemp;
float lastFirstTemp;
float lastSecondTemp;

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    // Override point for customization after application launch.
    cbCentralManager = [[CBCentralManager alloc] initWithDelegate:self queue: dispatch_get_main_queue()];
    
//    NSString *peripheralName = @"t-80-14.0-15.4-17.1";
//    NSArray *components = [peripheralName componentsSeparatedByString:@"-"];
//    NSString *batteryLevel = components[1];
//    NSString *beanTemp = components[2];
//    NSString *firstTemp = components[3];
//    NSString *secondTemp = components[4];
    
    [KeenClient sharedClientWithProjectID:@"596788dfc9e77c00015d95c6" andWriteKey:@"FABAED949EA97B1176795E759EB34DE5F33859CEDA77BD87935593DE1C6F983D2E606BF734B82DD06CB21F1E23372873CFF3960DC04B6EB8C2F378AA55530B121F61B52E8D7F1FE0E5D3F80A87BC52D6D014793301209BDAF2A83C5A93E1273B" andReadKey: nil];

    [[ KeenClient sharedClient ] setMaxEventUploadAttempts: 1569325000];

    return YES;
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
        [self restartScan ];
    } else {
        NSLog(@"bluetooth not on");
    }
    
}

-(void) restartScan {
    NSDictionary *options = [NSDictionary dictionaryWithObjectsAndKeys:
                             [NSNumber numberWithBool:YES], CBCentralManagerScanOptionAllowDuplicatesKey,
                             nil];
    
    [cbCentralManager stopScan ];
    [ cbCentralManager scanForPeripheralsWithServices:nil options:options ];
    
    NSLog(@"Restarted scanning");
}

-(void)centralManager:(CBCentralManager *)central didDiscoverPeripheral:(CBPeripheral *)peripheral advertisementData:(NSDictionary<NSString *,id> *)advertisementData RSSI:(NSNumber *)RSSI {

    UIViewController* mainController = (UIViewController*)  self.window.rootViewController;
    NSString *peripheralName = [peripheral name];
    
    if ( ! [peripheralName hasPrefix:@"t/"] ) {
        return;
    }

    NSLog(@"BT discovered %@ (%@)", peripheralName, RSSI);

    NSArray *components = [peripheralName componentsSeparatedByString:@"/"];
    int batteryLevel = [components[1] floatValue];
    float beanTemp = [components[2] floatValue];
    float firstTemp = [components[3] floatValue];
    float secondTemp = [components[4] floatValue];

    NSDate *currentDateAndTime = [NSDate date];
    NSDateFormatter *timeFormat = [[NSDateFormatter alloc] init];
    [timeFormat setDateFormat:@"HH:mm:ss"];
    NSString *timeString = [timeFormat stringFromDate:currentDateAndTime];
    
    for (id v in mainController.view.subviews) {
        UILabel *label = v;

        if ([[v accessibilityLabel] isEqualToString: @"akku"]) {
            [label setText: components[1]];
        }
        if ([[v accessibilityLabel] isEqualToString: @"ilma"]) {
            [label setText: components[2]];
        }
        if ([[v accessibilityLabel] isEqualToString: @"vesi"]) {
            [label setText: components[3]];
        }
        if ([[v accessibilityLabel] isEqualToString: @"sauna"]) {
            [label setText: components[4]];
        }
        if ([[v accessibilityLabel] isEqualToString: @"päivitys"]) {
            [label setText: timeString];
        }
    }
    
    if (
        lastBeanTemp == beanTemp &&
        lastFirstTemp == firstTemp &&
        lastSecondTemp == secondTemp
        ) {
        NSLog(@"Values are the same, not updating");
        return;
    }

    lastBeanTemp = beanTemp;
    lastFirstTemp = firstTemp;
    lastSecondTemp = secondTemp;
    
    NSDictionary *event = [NSDictionary dictionaryWithObjectsAndKeys:
                           [NSNumber numberWithInt: batteryLevel], @"batteryLevel",
                           [NSNumber numberWithFloat: beanTemp], @"beanTemp",
                           [NSNumber numberWithFloat: firstTemp], @"firstTemp",
                           [NSNumber numberWithFloat: secondTemp], @"secondTemp",
                           nil];
    
    [[KeenClient sharedClient] addEvent:event toEventCollection:@"temps" error:nil];
    [[KeenClient sharedClient] uploadWithFinishedBlock:nil ];
    
    NSLog(@"Sent to keen");
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
