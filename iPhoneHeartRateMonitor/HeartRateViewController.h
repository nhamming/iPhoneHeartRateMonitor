//
//  HeartRateViewController.h
//  HeartRateTest
//
//  Created by Nathaniel Hamming on 11-12-16.
//  Copyright (c) 2011 UHN. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <CoreBluetooth/CoreBluetooth.h>

@interface HeartRateViewController : UIViewController <CBCentralManagerDelegate, CBPeripheralDelegate> {
    
    CBCentralManager *manager;
    CBPeripheral *peripheral;
    NSMutableArray *heartRateMonitors;
    NSString *manufacturer;
    uint16_t heartRate;
    BOOL autoConnect;
    
    IBOutlet UIButton * indicatorButton;
    IBOutlet UIButton* connectButton;
    IBOutlet UIActivityIndicatorView *progressIndicator;    
    IBOutlet UILabel *heartRateLabel;
    IBOutlet UILabel *connectionState;
    IBOutlet UILabel *manufacturerLabel;
    IBOutlet UILabel *peripheralConnectMessage;
    IBOutlet UITableView *aTableView;
    IBOutlet UIImageView *heartPulseImageView;
}

@property (assign) uint16_t heartRate;
@property (retain) NSTimer *pulseTimer;
@property (retain) NSMutableArray *heartRateMonitors;
@property (copy) NSString *manufacturer;
@property (copy) NSString *connected;

- (IBAction) openScanSheet:(id) sender;
- (IBAction) closeScanSheet:(id)sender;
- (IBAction) cancelScanSheet:(id)sender;
- (IBAction) connectButtonPressed:(id)sender;

- (void) startScan;
- (void) stopScan;
- (BOOL) isLECapableHardware;

- (void) pulse;
- (void) updateWithHRMData:(NSData *)data;

@end
