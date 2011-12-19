//
//  AppDelegate.h
//  iPhoneHeartRateMonitor
//
//  Created by Nathaniel Hamming on 11-12-19.
//  Copyright (c) 2011 UHN. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "HeartRateViewController.h"

@interface AppDelegate : UIResponder <UIApplicationDelegate>

@property (nonatomic, retain) HeartRateViewController *viewController;
@property (strong, nonatomic) UIWindow *window;

@end
