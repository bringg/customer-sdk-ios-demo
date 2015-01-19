//
//  ViewController.m
//  BringgTrackingSDKDemo
//
//  Created by Ilya Kalinin on 12/17/14.
//  Copyright (c) 2014 Ilya Kalinin. All rights reserved.
//

#import "ViewController.h"

@interface ViewController ()

@property (nonatomic, strong) BringgTracker *tracker;

@end

@implementation ViewController

- (id)initWithCoder:(NSCoder *)aDecoder {
    if (self = [super initWithCoder:aDecoder]) {
        self.tracker = [[BringgTracker alloc] init];
        [self.tracker setConnectionDelegate:self];
        
    }
    return self;
    
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.

}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.

}

- (IBAction)connect:(id)sender {
    if ([self.tracker isConnected]) {
        NSLog(@"disconnecting");
        [self.tracker disconnect];
        
    } else {
        NSLog(@"connecting");
        [self.tracker connect];
    
    }
}

- (IBAction)monitorOrder:(id)sender {
    NSString *uuid = self.orderField.text;
    NSString *shareuuid = self.uuidField.text;
    
    if (uuid && [uuid length]) {
        if ([self.tracker isWatchingOrderWithUUID:uuid]) {
            [self.tracker stopWatchingOrderWithUUID:uuid shareUUID:shareuuid];
            [self.orderButton setTitle:@"Monitor Order" forState:UIControlStateNormal];
            
        } else {
            [self.tracker startWatchingOrederWithUUID:uuid shareUUID:shareuuid delegate:self];
            [self.orderButton setTitle:@"Stop Monitor Order" forState:UIControlStateNormal];
            
        }
    }
}

- (IBAction)monitorDriver:(id)sender {
    NSString *uuid = self.driverField.text;
    NSString *shareuuid = self.uuidField.text;
    if (uuid && [uuid length]) {
        if ([self.tracker isWatchingDriverWithUUID:uuid]) {
            [self.tracker stopWatchingDriverWithUUID:uuid shareUUID:shareuuid];
            [self.driverButton setTitle:@"Monitor Driver" forState:UIControlStateNormal];
            
        } else {
            [self.tracker startWatchingDriverWithUUID:uuid shareUUID:shareuuid delegate:self];
            [self.driverButton setTitle:@"Stop Monitor Driver" forState:UIControlStateNormal];
            
        }
    }
}

#pragma mark - 

- (void)trackerDidConnected {
    NSLog(@"connected");
    self.connectionLabel.text = @"BringgTracker: connected";
    [self.connectionButton setTitle:@"Disconnect" forState:UIControlStateNormal];
    
}

- (void)trackerDidDisconnectedWithError:(NSError *)error {
    NSLog(@"disconnected %@", error);
    self.connectionLabel.text = [NSString stringWithFormat:@"BringgTracker: disconnected %@", error];
    [self.connectionButton setTitle:@"Connect" forState:UIControlStateNormal];
   
}

- (void)watchOrderFailedForOrederWithUUID:(NSString *)uuid error:(NSError *)error {
    self.orderLabel.text = [NSString stringWithFormat:@"Failed %@, error %@", uuid, error];
    [self.orderButton setTitle:@"Monitor Order" forState:UIControlStateNormal];
    
}

- (void)orderDidAssignedWithOrderUUID:(NSString *)uuid driverUUID:(NSString *)driverUUID {
    self.orderLabel.text = [NSString stringWithFormat:@"Order assigned %@ for driver %@", uuid, driverUUID];
     
}

- (void)orderDidAcceptedOrderUUID:(NSString *)uuid {
    self.orderLabel.text = [NSString stringWithFormat:@"Order accepted %@", uuid];
    
}

- (void)orderDidStartedOrderUUID:(NSString *)uuid {
    self.orderLabel.text = [NSString stringWithFormat:@"Order started %@", uuid];
    
}

- (void)orderDidArrivedOrderUUID:(NSString *)uuid {
    self.orderLabel.text = [NSString stringWithFormat:@"Order arrived %@", uuid];
    
}

- (void)orderDidFinishedOrderUUID:(NSString *)uuid {
    self.orderLabel.text = [NSString stringWithFormat:@"Order finished %@", uuid];
    
}

- (void)orderDidCancelledOrderUUID:(NSString *)uuid {
    self.orderLabel.text = [NSString stringWithFormat:@"Order cancelled %@", uuid];
    
}

- (void)watchDriverFailedForDriverWithUUID:(NSString *)uuid error:(NSError *)error {
    self.driverLabel.text = [NSString stringWithFormat:@"Monitoring failed for %@, error %@", uuid, error];
    [self.driverButton setTitle:@"Monitor Driver" forState:UIControlStateNormal];
    
}

- (void)driverLocationDidChangedWithDriverUUID:(NSString *)driverUUID lat:(NSNumber *)lat lng:(NSNumber *)lng {
    self.driverLabel.text = [NSString stringWithFormat:@"uuid %@, lat %@, lng %@", driverUUID, lat, lng];
    
}

@end
