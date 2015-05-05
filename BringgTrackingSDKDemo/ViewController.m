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
@property (nonatomic, strong) BringgCustomer *customer;

@end

@implementation ViewController

- (id)initWithCoder:(NSCoder *)aDecoder {
    if (self = [super initWithCoder:aDecoder]) {
        self.customer = [[BringgCustomer alloc] init];
        self.tracker = [[BringgTracker alloc] init];
        [self.tracker setCustomer:self.customer];
        [self.tracker setConnectionDelegate:self];
        
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
    if ([self.tracker isConnected]) {
        NSLog(@"disconnecting");
        [self.tracker disconnect];
        
    } else {
        NSLog(@"connecting");
        NSString *token = self.customerTokenField.text;
        [self.tracker connectWithCustomerToken:token];
    
    }
}

- (IBAction)monitorOrder:(id)sender {
    NSString *uuid = self.orderField.text;
    if (uuid && [uuid length]) {
        if ([self.tracker isWatchingOrderWithUUID:uuid]) {
            [self.tracker stopWatchingOrderWithUUID:uuid];
            [self.orderButton setTitle:@"Monitor Order" forState:UIControlStateNormal];
            
        } else {
            [self.tracker startWatchingOrederWithUUID:uuid delegate:self];
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

- (IBAction)signin:(id)sender {
    //signin to get customer token
    [self.customer setDeveloperToken:self.developerTokenField.text];
    [self.customer signInWithName:self.customerNameField.text
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
    [self.tracker rateWithRating:[self.customerRatingField.text integerValue] shareUUID:self.uuidField.text completionHandler:^(BOOL success, NSError *error) {
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
    self.driverLabel.text = [NSString stringWithFormat:@"lat %@, lng %@", lat, lng];
    
}

@end
