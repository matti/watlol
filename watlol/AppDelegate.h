//
//  AppDelegate.h
//  watlol
//
//  Created by mpa on 25/06/2017.
//  Copyright © 2017 mpa. All rights reserved.
//

#import <UIKit/UIKit.h>
@import CoreBluetooth;

@interface AppDelegate : UIResponder <UIApplicationDelegate, CBCentralManagerDelegate>
@property (strong, nonatomic) UIWindow *window;
@end

@interface MovingAverage : NSObject {
    NSMutableArray *samples;
    int sampleCount;
    int averageSize;
    int size;
}
-(id)initWithSize:(int)size;
-(void)addSample:(float)sample;
-(float)movingAverage;
@end
