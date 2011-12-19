//
//  HeartRateViewController.m
//  HeartRateTest
//
//  Created by Nathaniel Hamming on 11-12-16.
//  Copyright (c) 2011 UHN. All rights reserved.
//

#import "HeartRateViewController.h"

@interface HeartRateViewController () <UITableViewDataSource, UITableViewDelegate>
@property (nonatomic, retain) UITableView *aTableView;
@property (nonatomic, retain) UILabel *heartRateLabel;
@property (nonatomic, retain) UILabel *manufacturerLabel;
@property (nonatomic, retain) UIImageView *heartPulseImageView;
@property (nonatomic, retain) UILabel *peripheralConnectMessage;
@end

@implementation HeartRateViewController

@synthesize heartRate;
@synthesize pulseTimer;
@synthesize heartRateMonitors;
@synthesize manufacturer;
@synthesize connected;
@synthesize aTableView;
@synthesize heartRateLabel;
@synthesize manufacturerLabel;
@synthesize heartPulseImageView;
@synthesize peripheralConnectMessage;

- (void)dealloc {
    self.pulseTimer = nil;
    self.heartRateMonitors = nil;
    self.aTableView = nil;
    self.heartRateLabel = nil;
    self.manufacturerLabel = nil;
    self.heartPulseImageView = nil;
    self.peripheralConnectMessage = nil;
    [super dealloc];
}

#pragma mark - View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.heartRateMonitors = [NSMutableArray array];
    manager = [[CBCentralManager alloc] initWithDelegate:self queue:nil];
}

#pragma mark - Peripheral Table methods

- (void)displayPeripheralTable 
{
    if( [self isLECapableHardware] )
    {
        autoConnect = FALSE;
        [self.aTableView reloadData];
        self.aTableView.hidden = NO;
        self.peripheralConnectMessage.hidden = NO;
        [connectButton setTitle: @"Cancel" forState: UIControlStateNormal];
        [self startScan];
    }
}

- (void)dismissPeripheralTable
{
    self.aTableView.hidden = YES;
    progressIndicator.hidden = YES;
    self.peripheralConnectMessage.hidden = YES;
    [self.heartRateMonitors removeAllObjects];
}

#pragma mark - Connect Button

/*
 This method is called when connect button pressed and it takes appropriate actions depending on device connection state
 */
- (IBAction)connectButtonPressed:(id)sender
{
    if(peripheral && ([peripheral isConnected]))
    { 
        /* Disconnect if it's already connected */
        [manager cancelPeripheralConnection:peripheral]; 
    }
    else if (peripheral)
    {
        /* Device is not connected, cancel pending connection */
        progressIndicator.hidden = YES;
        [connectButton setTitle: @"Connect" forState: UIControlStateNormal];
        [manager cancelPeripheralConnection:peripheral];
        [self displayPeripheralTable];
    }
    else if (!self.aTableView.hidden)
    {
        /* cancelling connecting to peripheral. Peripherals detected, but not connected */
        [connectButton setTitle: @"Connect" forState: UIControlStateNormal];
        [self dismissPeripheralTable];
    }
    else
    {   /* No outstanding connection, open peripheral table */
        progressIndicator.hidden = NO;
        [self displayPeripheralTable];
    }
}

#pragma mark - Heart Rate Data

/* 
 Update UI with heart rate data received from device
 */
- (void) updateWithHRMData:(NSData *)data 
{
    const uint8_t *reportData = [data bytes];
    uint16_t bpm = 0;
    
    if ((reportData[0] & 0x01) == 0) 
    {
        /* uint8 bpm */
        bpm = reportData[1];
    } 
    else 
    {
        /* uint16 bpm */
        bpm = CFSwapInt16LittleToHost(*(uint16_t *)(&reportData[1]));
    }
    
    uint16_t oldBpm = self.heartRate;
    self.heartRate = bpm;
    self.heartRateLabel.text = [NSString stringWithFormat: @"%d", self.heartRate];
    if (!self.pulseTimer) {
        self.pulseTimer = [NSTimer scheduledTimerWithTimeInterval:(60. / heartRate) target:self selector:@selector(pulse) userInfo:nil repeats: YES];        
    } else if (oldBpm != self.heartRate) {
        [self.pulseTimer invalidate];
        self.pulseTimer = [NSTimer scheduledTimerWithTimeInterval:(60. / heartRate) target:self selector:@selector(pulse) userInfo:nil repeats: YES];        
    }
}

/*
 Update pulse UI
 */
- (void) pulse 
{
    [UIView animateWithDuration: 0.2 
                     animations: ^{
                         CGAffineTransform contextScale = CGAffineTransformMakeScale(1.2, 1.2);
                         self.heartPulseImageView.transform = contextScale;
                     }
                     completion: ^(BOOL finished){
                         CGAffineTransform contextScale = CGAffineTransformMakeScale(1, 1);
                         self.heartPulseImageView.transform = contextScale;                         
                     }];
}

#pragma mark - Battery Data

- (void)readValueForCharacteristic:(CBCharacteristic *)characteristic {
    
}

- (void)updateBatteryStatus {
    
}

#pragma mark - Start/Stop Scan methods

/*
 Uses CBCentralManager to check whether the current platform/hardware supports Bluetooth LE. An alert is raised if Bluetooth LE is not enabled or is not supported.
 */
- (BOOL) isLECapableHardware
{
    NSString * state = nil;
    
    switch ([manager state]) 
    {
        case CBCentralManagerStateUnsupported:
            state = @"The platform/hardware doesn't support Bluetooth Low Energy.";
            break;
        case CBCentralManagerStateUnauthorized:
            state = @"The app is not authorized to use Bluetooth Low Energy.";
            break;
        case CBCentralManagerStatePoweredOff:
            state = @"Bluetooth is currently powered off.";
            break;
        case CBCentralManagerStatePoweredOn:
            return TRUE;
        case CBCentralManagerStateUnknown:
        default:
            return FALSE;
            
    }
    
    NSLog(@"Central manager state: %@", state);
    
    [self dismissPeripheralTable];
    
    UIAlertView *alert = [[[UIAlertView alloc] initWithTitle: nil message: state delegate: nil cancelButtonTitle: @"OK" otherButtonTitles:nil] autorelease];
    [alert show];
    return FALSE;
}

/*
 Request CBCentralManager to scan for heart rate peripherals using service UUID 0x180D
 */
- (void) startScan 
{
    [manager scanForPeripheralsWithServices:nil options:nil]; 
    //    [manager scanForPeripheralsWithServices:[NSArray arrayWithObject:[CBUUID UUIDWithString:@"180D"]] options:nil];
}

/*
 Request CBCentralManager to stop scanning for heart rate peripherals
 */
- (void) stopScan 
{
    [manager stopScan];
}

#pragma mark - CBCentralManager delegate methods
/*
 Invoked whenever the central manager's state is updated.
 */
- (void) centralManagerDidUpdateState:(CBCentralManager *)central 
{
    [self isLECapableHardware];
}

/*
 Invoked when the central discovers heart rate peripheral while scanning.
 */
- (void) centralManager:(CBCentralManager *)central didDiscoverPeripheral:(CBPeripheral *)aPeripheral advertisementData:(NSDictionary *)advertisementData RSSI:(NSNumber *)RSSI 
{    
    NSLog(@"peripheral: %@", aPeripheral);
    
    NSMutableArray *peripherals = [self mutableArrayValueForKey:@"heartRateMonitors"];
    if( ![peripherals containsObject:aPeripheral] )
        [peripherals addObject:aPeripheral];
    
    /* Retreive already known devices */
    if(autoConnect)
    {
        [manager retrievePeripherals:[NSArray arrayWithObject:(id)aPeripheral.UUID]];
    } 

    [self.aTableView reloadData];

}

/*
 Invoked when the central manager retrieves the list of known peripherals.
 Automatically connect to first known peripheral
 */
- (void)centralManager:(CBCentralManager *)central didRetrievePeripherals:(NSArray *)peripherals
{
    NSLog(@"Retrieved peripheral: %d - %@", [peripherals count], peripherals);
    
    [self stopScan];
    
    /* If there are any known devices, automatically connect to it.*/
    if([peripherals count] >=1)
    {
        peripheral = [peripherals objectAtIndex:0];
        [peripheral retain];
        [connectButton setTitle:@"Cancel" forState: UIControlStateNormal];
        [manager connectPeripheral:peripheral options:[NSDictionary dictionaryWithObject:[NSNumber numberWithBool:YES] forKey:CBConnectPeripheralOptionNotifyOnDisconnectionKey]];
    }
}

/*
 Invoked whenever a connection is succesfully created with the peripheral. 
 Discover available services on the peripheral
 */
- (void) centralManager:(CBCentralManager *)central didConnectPeripheral:(CBPeripheral *)aPeripheral 
{    
    [aPeripheral setDelegate:self];
    [aPeripheral discoverServices:nil];
	
	self.connected = @"Connected";
    [connectButton setTitle:@"Disconnect" forState: UIControlStateNormal];
    self.aTableView.hidden = YES;
    progressIndicator.hidden = YES;
    self.peripheralConnectMessage.hidden = YES;
}

/*
 Invoked whenever an existing connection with the peripheral is torn down. 
 Reset local variables
 */
- (void)centralManager:(CBCentralManager *)central didDisconnectPeripheral:(CBPeripheral *)aPeripheral error:(NSError *)error
{
    [self.pulseTimer invalidate];
	self.connected = @"Not connected";
    [connectButton setTitle:@"Connect" forState: UIControlStateNormal];
    self.manufacturer = @"N/A";
    self.manufacturerLabel.text = self.manufacturer;
    self.heartRateLabel.text = @"bpm";
    [self.heartRateMonitors removeAllObjects];
    if( peripheral )
    {
        [peripheral setDelegate:nil];
        peripheral = nil;
    }
}

/*
 Invoked whenever the central manager fails to create a connection with the peripheral.
 */
- (void)centralManager:(CBCentralManager *)central didFailToConnectPeripheral:(CBPeripheral *)aPeripheral error:(NSError *)error
{
    NSLog(@"Fail to connect to peripheral: %@ with error = %@", aPeripheral, [error localizedDescription]);
    [connectButton setTitle:@"Connect" forState: UIControlStateNormal]; 
    if( peripheral )
    {
        [peripheral setDelegate:nil];
        [peripheral release];
        peripheral = nil;
    }
}

#pragma mark - CBPeripheral delegate methods
/*
 Invoked upon completion of a -[discoverServices:] request.
 Discover available characteristics on interested services
 */
- (void) peripheral:(CBPeripheral *)aPeripheral didDiscoverServices:(NSError *)error 
{
    for (CBService *aService in aPeripheral.services) 
    {
        NSLog(@"Service found with UUID: %@", aService.UUID);
        
        /* Heart Rate Service */
        if ([aService.UUID isEqual:[CBUUID UUIDWithString:@"180D"]]) 
        {
            [aPeripheral discoverCharacteristics:nil forService:aService];
        }
        
        /* Device Information Service */
        if ([aService.UUID isEqual:[CBUUID UUIDWithString:@"180A"]]) 
        {
            [aPeripheral discoverCharacteristics:nil forService:aService];
        }
        
        /* GAP (Generic Access Profile) for Device Name */
        if ( [aService.UUID isEqual:[CBUUID UUIDWithString:CBUUIDGenericAccessProfileString]] )
        {
            [aPeripheral discoverCharacteristics:nil forService:aService];
        }
    }
}

/*
 Invoked upon completion of a -[discoverCharacteristics:forService:] request.
 Perform appropriate operations on interested characteristics
 */
- (void) peripheral:(CBPeripheral *)aPeripheral didDiscoverCharacteristicsForService:(CBService *)service error:(NSError *)error 
{    
    NSLog(@"service.UUID: %@", service.UUID);
    
    if ([service.UUID isEqual:[CBUUID UUIDWithString:@"180D"]]) 
    {
        for (CBCharacteristic *aChar in service.characteristics) 
        {
            /* Set notification on heart rate measurement */
            if ([aChar.UUID isEqual:[CBUUID UUIDWithString:@"2A37"]]) 
            {
                [peripheral setNotifyValue:YES forCharacteristic:aChar];
                NSLog(@"Found a Heart Rate Measurement Characteristic");
            }
            /* Read body sensor location */
            if ([aChar.UUID isEqual:[CBUUID UUIDWithString:@"2A38"]]) 
            {
                [aPeripheral readValueForCharacteristic:aChar];
                NSLog(@"Found a Body Sensor Location Characteristic");
            } 
            
            /* Write heart rate control point */
            if ([aChar.UUID isEqual:[CBUUID UUIDWithString:@"2A39"]])
            {
                uint8_t val = 1;
                NSData* valData = [NSData dataWithBytes:(void*)&val length:sizeof(val)];
                [aPeripheral writeValue:valData forCharacteristic:aChar type:CBCharacteristicWriteWithResponse];
            }
        }
    }
    
    if ( [service.UUID isEqual:[CBUUID UUIDWithString:CBUUIDGenericAccessProfileString]] )
    {
        for (CBCharacteristic *aChar in service.characteristics) 
        {
            /* Read device name */
            if ([aChar.UUID isEqual:[CBUUID UUIDWithString:CBUUIDDeviceNameString]]) 
            {
                [aPeripheral readValueForCharacteristic:aChar];
                NSLog(@"Found a Device Name Characteristic");
            }
        }
    }
    
    if ([service.UUID isEqual:[CBUUID UUIDWithString:@"180A"]]) 
    {
        for (CBCharacteristic *aChar in service.characteristics) 
        {
            /* Read manufacturer name */
            if ([aChar.UUID isEqual:[CBUUID UUIDWithString:@"2A29"]]) 
            {
                [aPeripheral readValueForCharacteristic:aChar];
                NSLog(@"Found a Device Manufacturer Name Characteristic");
            }
        }
    }
}

/*
 Invoked upon completion of a -[readValueForCharacteristic:] request or on the reception of a notification/indication.
 */
- (void) peripheral:(CBPeripheral *)aPeripheral didUpdateValueForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error 
{
    /* Updated value for heart rate measurement received */
    if ([characteristic.UUID isEqual:[CBUUID UUIDWithString:@"2A37"]]) 
    {
        if( (characteristic.value)  || !error )
        {
            /* Update UI with heart rate data */
            [self updateWithHRMData:characteristic.value];
        }
    } 
    /* Value for body sensor location received */
    else  if ([characteristic.UUID isEqual:[CBUUID UUIDWithString:@"2A38"]]) 
    {
        NSData * updatedValue = characteristic.value;        
        uint8_t* dataPointer = (uint8_t*)[updatedValue bytes];
        if(dataPointer)
        {
            uint8_t location = dataPointer[0];
            NSString*  locationString;
            switch (location)
            {
                case 0:
                    locationString = @"Other";
                    break;
                case 1:
                    locationString = @"Chest";
                    break;
                case 2:
                    locationString = @"Wrist";
                    break;
                case 3:
                    locationString = @"Finger";
                    break;
                case 4:
                    locationString = @"Hand";
                    break;
                case 5:
                    locationString = @"Ear Lobe";
                    break;
                case 6: 
                    locationString = @"Foot";
                    break;
                default:
                    locationString = @"Reserved";
                    break;
            }
            NSLog(@"Body Sensor Location = %@ (%d)", locationString, location);
        }
    }
    /* Value for device Name received */
    else if ([characteristic.UUID isEqual:[CBUUID UUIDWithString:CBUUIDDeviceNameString]])
    {
        NSString * deviceName = [[[NSString alloc] initWithData:characteristic.value encoding:NSUTF8StringEncoding] autorelease];
        NSLog(@"Device Name = %@", deviceName);
    } 
    /* Value for manufacturer name received */
    else if ([characteristic.UUID isEqual:[CBUUID UUIDWithString:@"2A29"]]) 
    {
        self.manufacturer = [[[NSString alloc] initWithData:characteristic.value encoding:NSUTF8StringEncoding] autorelease];
        NSLog(@"Manufacturer Name = %@", self.manufacturer);
        self.manufacturerLabel.text = self.manufacturer;
    }
}

#pragma mark - UITableView Datasource

- (NSInteger)numberOfSectionsInTableView: (UITableView*)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [self.heartRateMonitors count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
	static NSString *CellIdentifier = @"TableViewCell";
	
	UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
	if (cell == nil) {
		cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier] autorelease];
	}
    cell.accessoryType = UITableViewCellAccessoryNone;
    
    NSLog(@"heartRateMonitors: %@", self.heartRateMonitors);
    if ([[self.heartRateMonitors objectAtIndex: indexPath.row] isKindOfClass:[CBPeripheral class]]) {
        cell.textLabel.text = [[self.heartRateMonitors objectAtIndex: indexPath.row] name];
    } else {
        cell.textLabel.text = @"Not a CBPeripheral!!";
    }
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView cellForRowAtIndexPath: indexPath];
    cell.accessoryType = UITableViewCellAccessoryCheckmark;
    peripheral = [self.heartRateMonitors objectAtIndex: indexPath.row];
    [manager connectPeripheral: peripheral options:nil];
    [tableView deselectRowAtIndexPath: indexPath animated: YES];
}

@end
