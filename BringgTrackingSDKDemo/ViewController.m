//
//  ViewController.m
//  BringgTrackingSDKDemo
//
//  Created by Ilya Kalinin on 12/17/14.
//  Copyright (c) 2014 Ilya Kalinin. All rights reserved.
//

#import "ViewController.h"
#import "GGCustomer.h"
#import "GGDriver.h"
#import "GGSharedLocation.h"
#import "GGOrder.h"
#import "GGOrderBuilder.h"
#import "GGRealTimeMontior.h"




@interface ViewController ()

@property (nonatomic, strong) GGTrackerManager *trackerManager;
@property (nonatomic, strong) GGHTTPClientManager *httpManager;
@property (nonatomic, strong) NSString *hardCodedConfermationId;
@property (nonatomic, strong) NSString *hardCodedMerchandId;
@end

@implementation ViewController

- (id)initWithCoder:(NSCoder *)aDecoder {
    if (self = [super initWithCoder:aDecoder]) {
    
        // at first we should just init the http client manager
        self.httpManager = [GGHTTPClientManager sharedInstance];
        _hardCodedConfermationId = @"2865";
        _hardCodedMerchandId = @"734";
        
    }
    
    return self;
    
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // Dismiss the keyboard when the user taps outside of a text field
    UITapGestureRecognizer *singleTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(hideKeyBoard)];
    [self.view addGestureRecognizer:singleTap];
    singleTap.cancelsTouchesInView = NO;
    
#warning HACK - this uses private api - dont publish this part
    
 

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
        if (self.trackerManager) {
            [self.trackerManager disconnect];
        }
        
    } else if (self.trackerManager){
        NSLog(@"connecting");
        [self.trackerManager connect];
    
    }
}

- (IBAction)monitorOrder:(id)sender {
    
#warning TODO - change this to take order id and then get the true order object form the "get order by id " method
    
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
    
    
    
    [self.httpManager setDeveloperToken:self.developerTokenField.text];
    [self.httpManager signInWithName:self.customerNameField.text
                            phone:self.customerPhoneField.text
                confirmationCode:self.customerCodeField.text
                      merchantId:self.customerMerchantField.text

     completionHandler:^(BOOL success, GGCustomer *customer, NSError *error) {
         //
         
         if (customer) {
             
             
             // once we have a customer token we can activate the tracking manager
             self.trackerManager = [GGTrackerManager trackerWithCustomerToken:customer.customerToken
                                                            andDeveloperToken:self.developerTokenField.text andDelegate:self];
             
             self.customerTokenField.text = customer.customerToken;
             
             // set the customer in the tracker manager
             [self.trackerManager setCustomer:customer];
         }
     }];
}

- (IBAction)rate:(id)sender {
    
    // first we should gate the shared location object - only then can we rate
    [self.httpManager getSharedLocationByID:self.uuidField.text.integerValue withCompletionHandler:^(BOOL success, GGSharedLocation *sharedLocation, NSError *error) {
        //
        
        if (success && sharedLocation) {
            [self.httpManager rate:[self.customerRatingField.text intValue] withToken:sharedLocation.rating.token forSharedUUID:self.uuidField.text withCompletionHandler:^(BOOL success, GGRating *rating, NSError *error) {
                //
                NSLog(@"%@, error %@", success ? @"success" : @"failed", error);
                
            }];
        }
    }];
    
    
}

#pragma mark - RealTimeDelegate

- (void)trackerDidConnect {
    NSLog(@"connected");
    self.connectionLabel.text = @"BringgTracker: connected";
    [self.connectionButton setTitle:@"Disconnect" forState:UIControlStateNormal];
    
}

- (void)trackerDidDisconnectWithError:(NSError *)error{
    NSLog(@"disconnected %@", error);
    self.connectionLabel.text = [NSString stringWithFormat:@"BringgTracker: disconnected %@", error];
    [self.connectionButton setTitle:@"Connect" forState:UIControlStateNormal];
   
}


#pragma mark - OrderDelegate

- (void)watchOrderFailForOrder:(GGOrder *)order error:(NSError *)error{
    self.orderLabel.text = [NSString stringWithFormat:@"Failed %@, error %@", order.uuid, error];
    [self.orderButton setTitle:@"Monitor Order" forState:UIControlStateNormal];
}

- (void)orderDidAssignWithOrder:(GGOrder *)order withDriver:(GGDriver *)driver{
    self.orderLabel.text = [NSString stringWithFormat:@"Order assigned %@ for driver %@", order.uuid, driver.uuid];
    self.driverField.text = driver.uuid;
}

- (void)orderDidAcceptWithOrder:(GGOrder *)order withDriver:(GGDriver *)driver{
    self.orderLabel.text = [NSString stringWithFormat:@"Order accepted %@ for driver %@", order.uuid, driver.uuid];
    self.driverField.text = driver.uuid;
}

- (void)orderDidStartWithOrder:(GGOrder *)order withDriver:(GGDriver *)driver{
    self.orderLabel.text = [NSString stringWithFormat:@"Order started %@ for driver %@", order.uuid, driver.uuid];
    self.driverField.text = driver.uuid;
}

- (void)orderDidArrive:(GGOrder *)order{
    self.orderLabel.text = [NSString stringWithFormat:@"Order arrived %@", order.uuid];
}

- (void)orderDidFinish:(GGOrder *)order{
    self.orderLabel.text = [NSString stringWithFormat:@"Order finished %@", order.uuid];
}

- (void)orderDidCancel:(GGOrder *)order{
     self.orderLabel.text = [NSString stringWithFormat:@"Order canceled %@", order.uuid];
}


#pragma mark - DriverDelegate

- (void)watchDriverFailedForDriver:(GGDriver *)driver error:(NSError *)error{
    self.driverLabel.text = [NSString stringWithFormat:@"Monitoring failed for %@, error %@", driver.uuid, error];
    [self.driverButton setTitle:@"Monitor Driver" forState:UIControlStateNormal];
}

- (void)driverLocationDidChangeWithDriver:(GGDriver *)driver{
    self.driverLabel.text = [NSString stringWithFormat:@"driver %@  is at %f,%f",driver.uuid, driver.latitude, driver.longitude];
}

- (void)driverLocationDidChangedWithDriverUUID:(NSString *)driverUUID lat:(NSNumber *)lat lng:(NSNumber *)lng {
    self.driverLabel.text = [NSString stringWithFormat:@"lat %@, lng %@", lat, lng];
    
}




@end
