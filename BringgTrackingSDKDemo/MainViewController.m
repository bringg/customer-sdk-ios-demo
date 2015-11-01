//
//  ViewController.m
//  BringgTrackingSDKDemo
//
//  Created by Matan Poreh on 12/17/14.
//  Copyright (c) 2014 Matan Poreh. All rights reserved.
//

#import "MainViewController.h"
#import "GGCustomer.h"
#import "GGDriver.h"
#import "GGSharedLocation.h"
#import "GGOrder.h"
#import "GGOrderBuilder.h"
#import "GGRealTimeMontior.h"

#define kBringgDeveloperToken @"YOUR_DEVELOPER_TOKEN_HERE"


@interface MainViewController ()

@property (nonatomic, strong) GGTrackerManager *trackerManager;
@property (nonatomic, strong) GGHTTPClientManager *httpManager;

@property (nonatomic, strong) NSMutableDictionary *monitoredOrders;
@property (nonatomic, strong) NSMutableDictionary *monitoredDrivers;
@end

@implementation MainViewController

- (id)initWithCoder:(NSCoder *)aDecoder {
    if (self = [super initWithCoder:aDecoder]) {
    
        // at first we should just init the http client manager
        [GGHTTPClientManager managerWithDeveloperToken:kBringgDeveloperToken];
        self.httpManager = [GGHTTPClientManager manager];
 
        // init the tracker without the customer token
        self.trackerManager = [GGTrackerManager tracker];
        [self.trackerManager setDeveloperToken:kBringgDeveloperToken];
        [self.trackerManager setRealTimeDelegate:self];
        

        _monitoredOrders = [NSMutableDictionary dictionary];
        _monitoredDrivers = [NSMutableDictionary dictionary];
        
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

- (void)viewWillAppear:(BOOL)animated{
    
    // add order button is available only when there is a customer logged in
    [_addOrder setEnabled:self.trackerManager.customer != nil];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];

}

- (void)hideKeyBoard {
    [self.orderField resignFirstResponder];
    [self.driverField resignFirstResponder];
    [self.shareUUIDField resignFirstResponder];
    [self.customerRatingField resignFirstResponder];
    [self.customerMerchantField resignFirstResponder];
    [self.customerNameField resignFirstResponder];
    [self.customerPhoneField resignFirstResponder];
    [self.customerTokenField resignFirstResponder];
    [self.customerCodeField resignFirstResponder];
    
}

- (IBAction)connect:(id)sender {
    if ([self.trackerManager isConnected]) {
        NSLog(@"disconnecting");
        if (self.trackerManager) {
            [self.trackerManager disconnect];
        }
        
    } else if (self.trackerManager){
        NSLog(@"connecting to http/https");
        [self.trackerManager connectUsingSecureConnection:YES];
    
    }
}

- (IBAction)monitorOrder:(id)sender {

    NSString *orderid = self.orderField.text;
    
    // if the customer signed in  we can use the http manager to get more data about
    // the order before doing the actual monitoring
    if ([self.httpManager isSignedIn]) {
        // get the order object and start monitoring it
        [self.httpManager getOrderByID:orderid.integerValue withCompletionHandler:^(BOOL success, GGOrder *order, NSError *error) {
            //
            if (success && order) {
                
                [self trackOrder:order];

            }else{
                if (error) {
                    UIAlertView  *alertView = [[UIAlertView alloc] initWithTitle:@"General Service Error" message:error.localizedDescription delegate:nil cancelButtonTitle:@"Ok" otherButtonTitles:nil];
                    
                    [alertView show];
                }
            }
            
        }];
        
    }else{
        // if customer not signed in  then it is our job to provide order uuid from the partner - api
        // make sure the orderfield now hold uuid
         NSString *orderuuid = self.orderField.text;
        
        // if no order object we create one with the uuid we got from the partner api and the 'Created' status
        GGOrder *order = [[GGOrder alloc] initOrderWithUUID:orderuuid atStatus:OrderStatusCreated];
        
        [self trackOrder:order];
    }
    
    
    
    
}

- (void)trackOrder:(GGOrder *)order{
    if ([self.trackerManager isWatchingOrderWithUUID:order.uuid]) {
        
        [_monitoredOrders setObject:[NSNull null] forKey:order.uuid];
        
        [self.trackerManager stopWatchingOrderWithUUID:order.uuid];
        [self.orderButton setTitle:@"Monitor Order" forState:UIControlStateNormal];
    }else{
        
        [_monitoredOrders setObject:order forKey:order.uuid];
        
        [self.trackerManager startWatchingOrderWithUUID:order.uuid delegate:self];
        [self.orderButton setTitle:@"Stop Monitor Order" forState:UIControlStateNormal];
    }
}

- (IBAction)monitorDriver:(id)sender {
    NSString *uuid = self.driverField.text;
    NSString *shareuuid = self.shareUUIDField.text;
    if (uuid && [uuid length]) {
        if ([self.trackerManager isWatchingDriverWithUUID:uuid]) {
            
            [_monitoredDrivers setObject:[NSNull null] forKey:uuid];
            
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
    
   
    
    [self.httpManager signInWithName:self.customerNameField.text
                            phone:self.customerPhoneField.text
                confirmationCode:self.customerCodeField.text
                      merchantId:self.customerMerchantField.text
                              extras:nil

     completionHandler:^(BOOL success, GGCustomer *customer, NSError *error) {
         //
         UIAlertView *alertView;
         
         if (customer) {
             
             alertView = [[UIAlertView alloc] initWithTitle:nil message:[NSString stringWithFormat:@"%@ Signed in", customer.name] delegate:nil cancelButtonTitle:@"Ok" otherButtonTitles:nil];
             
             [alertView show];
             
             if (!self.trackerManager) {
                 // once we have a customer token we can activate the tracking manager
                 [GGTrackerManager trackerWithCustomerToken:customer.customerToken
                                          andDeveloperToken:kBringgDeveloperToken
                                                andDelegate:self];
                 // then we can access the tracker singelton via his conveninence initialiser
                 self.trackerManager = [GGTrackerManager tracker];

             }
             
             self.customerTokenField.text = customer.customerToken;
             
             // set the customer in the tracker manager
             [self.trackerManager setCustomer:customer];
             
             
             
         }else if (error){
            alertView = [[UIAlertView alloc] initWithTitle:@"Sign in Error" message:error.localizedDescription delegate:nil cancelButtonTitle:@"Ok" otherButtonTitles:nil];
             
             [alertView show];
         }
     }];
}

- (IBAction)rate:(id)sender {
    
    // first we should gate the shared location object - only then can we rate
    [self.httpManager getSharedLocationByUUID:self.shareUUIDField.text withCompletionHandler:^(BOOL success, GGSharedLocation *sharedLocation, NSError *error) {
        //
        
        if (success && sharedLocation) {
           
            
            [self.httpManager rate:[self.customerRatingField.text intValue]
                         withToken:sharedLocation.rating.token
                         ratingURL:self.ratingURLField.text withCompletionHandler:^(BOOL success, GGRating *rating, NSError *error) {
                //
                UIAlertView *alertView;
                if (rating && rating.ratingMessage) {
                    alertView = [[UIAlertView alloc] initWithTitle:nil message:rating.ratingMessage delegate:nil cancelButtonTitle:@"Ok" otherButtonTitles:nil];
                    
                    [alertView show];
                }else if (error){
                    alertView = [[UIAlertView alloc] initWithTitle:@"Rating Error"  message:error.localizedDescription delegate:nil cancelButtonTitle:@"Ok" otherButtonTitles:nil];
                    
                    [alertView show];
                }
                
                
                NSLog(@"%@, error %@", success ? @"success" : @"failed", error);
                
            }];
        }
    }];
    
    
}

- (IBAction)addOrder:(id)sender {
    
    [self performSegueWithIdentifier:@"showAddOrder" sender:self];
    
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender{
    
    
    NSString *identifier = segue.identifier;
    
    if ([identifier isEqualToString:@"showAddOrder"]) {
        //
        
        AddOrderViewController *addVC = segue.destinationViewController;
        
        [addVC setDelegate:self];
    }
}

#pragma mark - RealTimeDelegate

- (void)trackerDidConnect {
    NSLog(@"connected");
    self.connectionLabel.text = @"BringgTracker: connected";
    [self.connectionButton setTitle:@"Disconnect" forState:UIControlStateNormal];
    
    // cant add orders without customer (sign in required)
    [_addOrder setEnabled:self.trackerManager.customer != nil];
    
}

- (void)trackerDidDisconnectWithError:(NSError *)error{
    NSLog(@"disconnected %@", error);
    self.connectionLabel.text = [NSString stringWithFormat:@"BringgTracker: disconnected %@", error];
    [self.connectionButton setTitle:@"Connect" forState:UIControlStateNormal];
    
    [_addOrder setEnabled:NO];
   
}


#pragma mark - Helpers

- (GGOrder *)updateMonitoredOrderWithOrder:(GGOrder *)order{
    
    GGOrder *monitoredOrder = [_monitoredOrders objectForKey:order.uuid];
    if (!monitoredOrder) {
        monitoredOrder = order;
        [_monitoredOrders setObject:monitoredOrder forKey:order.uuid];
    }else{
        [monitoredOrder updateOrderStatus:order.status];
    }

    return monitoredOrder;
}

#pragma mark - OrderDelegate

- (void)watchOrderFailForOrder:(GGOrder *)order error:(NSError *)error{
    
    NSString *errorMessage = [NSString stringWithFormat:@"%@.\nDid you enter the correct Order UUID?", error.localizedDescription.capitalizedString];
    
   UIAlertView* alertView = [[UIAlertView alloc] initWithTitle:@"Watch Order Error" message:errorMessage delegate:nil cancelButtonTitle:@"Ok" otherButtonTitles:nil];
    
    [alertView show];
    
    self.orderLabel.text = [NSString stringWithFormat:@"Failed %@, error %@", order.uuid, error];
    [self.orderButton setTitle:@"Monitor Order" forState:UIControlStateNormal];
    self.shareUUIDField.text = order.sharedLocation.locationUUID;
    self.ratingURLField.text = order.sharedLocation.ratingURL;
}

- (void)orderDidAssignWithOrder:(GGOrder *)order withDriver:(GGDriver *)driver{
    
    GGOrder *monitoredOrder = [self updateMonitoredOrderWithOrder:order];
    self.orderLabel.text = [NSString stringWithFormat:@"Order assigned %@ for driver %@", order.uuid, driver.uuid];
    self.driverField.text = driver.uuid;
    self.shareUUIDField.text = monitoredOrder.sharedLocation.locationUUID;
}

- (void)orderDidAcceptWithOrder:(GGOrder *)order withDriver:(GGDriver *)driver{
    
    GGOrder *monitoredOrder = [self updateMonitoredOrderWithOrder:order];
    self.orderLabel.text = [NSString stringWithFormat:@"Order accepted %@ for driver %@", order.uuid, driver.uuid];
    self.driverField.text = driver.uuid;
    self.shareUUIDField.text = monitoredOrder.sharedLocation.locationUUID;
}

- (void)orderDidStartWithOrder:(GGOrder *)order withDriver:(GGDriver *)driver{
    
    GGOrder *monitoredOrder = [self updateMonitoredOrderWithOrder:order];
    self.orderLabel.text = [NSString stringWithFormat:@"Order started %@ for driver %@", order.uuid, driver.uuid];
    self.driverField.text = driver.uuid;
    self.shareUUIDField.text = monitoredOrder.sharedLocation.locationUUID;
}

- (void)orderDidArrive:(GGOrder *)order withDriver:(GGDriver *)driver{
    
    GGOrder *monitoredOrder = [self updateMonitoredOrderWithOrder:order];
    self.orderLabel.text = [NSString stringWithFormat:@"Order arrived %@", order.uuid];
    self.shareUUIDField.text = monitoredOrder.sharedLocation.locationUUID;
}

-(void)orderDidFinish:(GGOrder *)order withDriver:(GGDriver *)driver{
    
    GGOrder *monitoredOrder = [self updateMonitoredOrderWithOrder:order];
    self.orderLabel.text = [NSString stringWithFormat:@"Order finished %@", order.uuid];
    self.shareUUIDField.text = monitoredOrder.sharedLocation.locationUUID;
}

- (void)orderDidCancel:(GGOrder *)order withDriver:(GGDriver *)driver{
    
    GGOrder *monitoredOrder = [self updateMonitoredOrderWithOrder:order];
    self.orderLabel.text = [NSString stringWithFormat:@"Order canceled %@", order.uuid];
    self.shareUUIDField.text = monitoredOrder.sharedLocation.locationUUID;
}


#pragma mark - DriverDelegate

- (void)watchDriverFailedForDriver:(GGDriver *)driver error:(NSError *)error{
    
    
    NSString *errorMessage = [NSString stringWithFormat:@"%@.\nDid you enter the correct Driver UUID & Share UUID?", error.localizedDescription.capitalizedString];
    
    UIAlertView* alertView = [[UIAlertView alloc] initWithTitle:@"Watch Driver Error" message:errorMessage delegate:nil cancelButtonTitle:@"Ok" otherButtonTitles:nil];
    
    [alertView show];
    
    self.driverLabel.text = [NSString stringWithFormat:@"Monitoring failed for %@, error %@", driver.uuid, error];
    [self.driverButton setTitle:@"Monitor Driver" forState:UIControlStateNormal];
}

- (void)driverLocationDidChangeWithDriver:(GGDriver *)driver{
    self.driverLabel.text = [NSString stringWithFormat:@"driver %@  is at %f,%f",driver.uuid, driver.latitude, driver.longitude];
}

- (void)driverLocationDidChangedWithDriverUUID:(NSString *)driverUUID lat:(NSNumber *)lat lng:(NSNumber *)lng {
    self.driverLabel.text = [NSString stringWithFormat:@"lat %@, lng %@", lat, lng];
    
}

#pragma mark - AddOrderDelegate

-(void)orderBuilderDidCreate:(GGOrderBuilder *)orderBuilder withController:(AddOrderViewController *)controller{
    
#warning Add Order SDK method not available yet
//    [self.httpManager addOrderWith:orderBuilder withCompletionHandler:^(BOOL success, GGOrder *order, NSError *error) {
//        //
//        UIAlertView *alertView;
//        if (success) {
//            alertView = [[UIAlertView alloc] initWithTitle:nil message:[NSString stringWithFormat:@"Success Adding Order %lu", order.orderid] delegate:nil cancelButtonTitle:@"Ok" otherButtonTitles:nil];
//            [alertView show];
//        }else if (error){
//            alertView = [[UIAlertView alloc] initWithTitle:@"Error adding order" message:error.localizedDescription delegate:nil cancelButtonTitle:@"Ok" otherButtonTitles:nil];
//            [alertView show];
//        }
//    }];
    
}


@end
