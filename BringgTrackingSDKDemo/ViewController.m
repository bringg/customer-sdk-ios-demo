//
//  ViewController.m
//  BringgTrackingSDKDemo
//
//  Created by Ilya Kalinin on 12/17/14.
//  Copyright (c) 2014 Ilya Kalinin. All rights reserved.
//

#import "ViewController.h"

@interface ViewController ()

@property (nonatomic, strong) BringgTrackerManager *trackerManager;
@property (nonatomic, strong) BringgCustomerManager *customerManager;

@end

@implementation ViewController

- (id)initWithCoder:(NSCoder *)aDecoder {
    if (self = [super initWithCoder:aDecoder]) {
        self.customerManager = [BringgCustomerManager sharedInstance];
        self.trackerManager = [BringgTrackerManager sharedInstance];
        [self.trackerManager setCustomerManager:self.customerManager];
        [self.trackerManager setConnectionDelegate:self];
        
    }
    return self;
    
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // Dismiss the keyboard when the user taps outside of a text field
    UITapGestureRecognizer *singleTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(hideKeyBoard)];
    [self.view addGestureRecognizer:singleTap];
    singleTap.cancelsTouchesInView = NO;
    


}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];

}

- (void)hideKeyBoard {
    [self.orderField resignFirstResponder];
    [self.driverField resignFirstResponder];
    [self.uuidField resignFirstResponder];
    [self.customerRatingField resignFirstResponder];
    [self.customerMerchantField resignFirstResponder];
    [self.customerNameField resignFirstResponder];
    [self.customerPhoneField resignFirstResponder];
    [self.customerTokenField resignFirstResponder];
    [self.developerTokenField resignFirstResponder];
    [self.customerCodeField resignFirstResponder];
    
}

- (IBAction)connect:(id)sender {
    if ([self.trackerManager isConnected]) {
        NSLog(@"disconnecting");
        [self.trackerManager disconnect];
        
    } else {
        NSLog(@"connecting");
        NSString *token = self.customerTokenField.text;
        [self.trackerManager connectWithCustomerToken:token];
    
    }
}

- (IBAction)monitorOrder:(id)sender {
    NSString *uuid = self.orderField.text;
    if (uuid && [uuid length]) {
        if ([self.trackerManager isWatchingOrderWithUUID:uuid]) {
            [self.trackerManager stopWatchingOrderWithUUID:uuid];
            [self.orderButton setTitle:@"Monitor Order" forState:UIControlStateNormal];
            
        } else {
            [self.trackerManager startWatchingOrderWithUUID:uuid delegate:self];
            [self.orderButton setTitle:@"Stop Monitor Order" forState:UIControlStateNormal];
            
        }
    }
}

- (IBAction)monitorDriver:(id)sender {
    NSString *uuid = self.driverField.text;
    NSString *shareuuid = self.uuidField.text;
    if (uuid && [uuid length]) {
        if ([self.trackerManager isWatchingDriverWithUUID:uuid]) {
            [self.trackerManager stopWatchingDriverWithUUID:uuid shareUUID:shareuuid];
            [self.driverButton setTitle:@"Monitor Driver" forState:UIControlStateNormal];
            
        } else {
            [self.trackerManager startWatchingDriverWithUUID:uuid shareUUID:shareuuid delegate:self];
            [self.driverButton setTitle:@"Stop Monitor Driver" forState:UIControlStateNormal];
            
        }
    }
}

- (IBAction)signin:(id)sender {
    //signin to get customer token
    [self.customerManager setDeveloperToken:self.developerTokenField.text];
    [self.customerManager signInWithName:self.customerNameField.text
                            phone:self.customerPhoneField.text
                 confirmationCode:self.customerCodeField.text
                       merchantId:self.customerMerchantField.text completionHandler:^(BOOL success, NSString *customerToken, NSError *error) {
                           if (success) {
                               NSLog(@"customerToken %@", customerToken);
                               self.customerTokenField.text = customerToken;
                               
                           } else {
                               NSLog(@"error %@", error);
                               
                           }
                       }];
}

- (IBAction)rate:(id)sender {
    [self.trackerManager rateWithRating:[self.customerRatingField.text integerValue] shareUUID:self.uuidField.text completionHandler:^(BOOL success, NSError *error) {
        NSLog(@"%@, error %@", success ? @"success" : @"failed", error);
        
    }];
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

- (void)watchOrderFailedForOrderWithUUID:(NSString *)uuid error:(NSError *)error {
    self.orderLabel.text = [NSString stringWithFormat:@"Failed %@, error %@", uuid, error];
    [self.orderButton setTitle:@"Monitor Order" forState:UIControlStateNormal];
    
}

- (void)orderDidAssignedWithOrderUUID:(NSString *)uuid driverUUID:(NSString *)driverUUID {
    self.orderLabel.text = [NSString stringWithFormat:@"Order assigned %@ for driver %@", uuid, driverUUID];
    self.driverField.text = driverUUID;
}

- (void)orderDidAcceptedOrderUUID:(NSString *)uuid driverUUID:(NSString *)driverUUID {
    self.orderLabel.text = [NSString stringWithFormat:@"Order accepted %@ for driver %@", uuid, driverUUID];
    self.driverField.text = driverUUID;
}

- (void)orderDidStartedOrderUUID:(NSString *)uuid driverUUID:(NSString *)driverUUID {
    self.orderLabel.text = [NSString stringWithFormat:@"Order started %@ for driver %@", uuid, driverUUID];
    self.driverField.text = driverUUID;
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
    self.driverLabel.text = [NSString stringWithFormat:@"lat %@, lng %@", lat, lng];
    
}

@end
