//
//  ViewController.m
//  BringgTrackingSDKDemo
//
//  Created by Matan Poreh on 12/17/14.
//  Copyright (c) 2014 Matan Poreh. All rights reserved.
//

#import "MainViewController.h"

#define kBringgDeveloperToken @"35yJM-zqQZHiwXG8_nBU"


@interface MainViewController ()

@property (nonatomic, strong) GGTrackerManager *trackerManager;
@property (nonatomic, strong) GGHTTPClientManager *httpManager;

@property (nonatomic, strong) NSMutableDictionary *monitoredOrders;
@property (nonatomic, strong) NSMutableDictionary *monitoredDrivers;
@property (nonatomic, strong) NSMutableDictionary *monitoredWaypoints;
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
        [self.trackerManager setHTTPManager:self.httpManager];
       

        _monitoredOrders = [NSMutableDictionary dictionary];
        _monitoredDrivers = [NSMutableDictionary dictionary];
         _monitoredWaypoints = [NSMutableDictionary dictionary];
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
    
    [super viewWillAppear:animated];
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
        [self.httpManager getOrderByID:orderid.integerValue extras:nil  withCompletionHandler:^(BOOL success, NSDictionary * response, GGOrder *order, NSError *error) {
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
        NSString *sharedUUID;
        NSString *orderCompound = self.orderCompoundField.text;
        
        if (orderCompound && orderCompound.length > 0) {
            [self monitorOrderWithCompoundUUID:orderCompound];
        }else{
            // if no order object we create one with the uuid we got from the partner api and the 'Created' status
            GGOrder *order = [[GGOrder alloc] initOrderWithUUID:orderuuid atStatus:OrderStatusCreated];
            order.sharedLocationUUID = sharedUUID;
            
            [self trackOrder:order];
        }

    }
    
    
    
    
}

- (void)monitorOrderWithCompoundUUID:(NSString *)compoundUUID{
    
    NSString *orderUUID;
    NSString *sharedUUID;
    NSError *error;

    [GGBringgUtils parseOrderCompoundUUID:compoundUUID toOrderUUID:&orderUUID andSharedUUID:&sharedUUID error:&error];
    
    if (error) {
        NSLog(@"cant monitor order :%@", error);
    }else{
        if ([self.trackerManager isWatchingOrderWithCompoundUUID:compoundUUID]) {
            [_monitoredOrders setObject:[NSNull null] forKey:orderUUID];
            [self.trackerManager stopWatchingOrderWithCompoundUUID:compoundUUID];
            [self.orderButton setTitle:@"Monitor Order" forState:UIControlStateNormal];
        }else{
            GGOrder *order = [[GGOrder alloc] initOrderWithUUID:orderUUID atStatus:OrderStatusCreated];
            order.sharedLocationUUID = sharedUUID;
            
            [_monitoredOrders setObject:order forKey:orderUUID];
            
            @try {
                [self.trackerManager startWatchingOrderWithCompoundUUID:compoundUUID delegate:self];
                [self.orderButton setTitle:@"Stop Monitor Order" forState:UIControlStateNormal];
            } @catch (NSException *exception) {
                NSLog(@"failed watching order %@", exception);
                
                [_monitoredOrders removeObjectForKey:orderUUID];
            }
            
        }
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
        if ([self.trackerManager isWatchingDriverWithUUID:uuid andShareUUID:shareuuid]) {
            
            [_monitoredDrivers setObject:[NSNull null] forKey:uuid];
            
            [self.trackerManager stopWatchingDriverWithUUID:uuid shareUUID:shareuuid];
            [self.driverButton setTitle:@"Monitor Driver" forState:UIControlStateNormal];
            
        } else {
            [self.trackerManager startWatchingDriverWithUUID:uuid shareUUID:shareuuid delegate:self];
            [self.driverButton setTitle:@"Stop Monitor Driver" forState:UIControlStateNormal];
            
        }
    }
}

- (IBAction)monitorWaypoint:(id)sender {
    
    if (self.waypointIdField.text && self.waypointIdField.text.length > 0) {
        
        NSNumber *wpid = @(self.waypointIdField.text.doubleValue);
        
        // check which order has this waypoint
        NSArray *allOrder = [self.monitoredOrders allValues];
        
        NSPredicate *predicateOrder = [NSPredicate predicateWithFormat:@"ANY waypoints.waypointId == %@",  wpid];
        
        NSString *orderUUID = [[[allOrder filteredArrayUsingPredicate:predicateOrder] firstObject] uuid];
        
        if (!orderUUID) {
            //
            UIAlertView  *alertView = [[UIAlertView alloc] initWithTitle:@"General Service Error" message:@"cant find order for waypoint" delegate:nil cancelButtonTitle:@"Ok" otherButtonTitles:nil];
            
            [alertView show];
            
            return;
        }
        
        if ([self.trackerManager isWatchingWaypointWithWaypointId:wpid andOrderUUID:orderUUID]) {
           [ _monitoredWaypoints setObject:[NSNull null] forKey:wpid];
            [self.trackerManager stopWatchingWaypointWithWaypointId:wpid andOrderUUID:orderUUID];
            [self.monitorWPButton setTitle:@"Monitor Waypoint" forState:UIControlStateNormal];
        }else{
            [self.trackerManager startWatchingWaypointWithWaypointId:wpid andOrderUUID:orderUUID delegate:self];
            [self.monitorWPButton setTitle:@"Stop Monitor Waypoint" forState:UIControlStateNormal];
        }
    }
    
}




- (IBAction)signin:(id)sender {
    //signin to get customer token
    
   
    
    [self.httpManager signInWithName:self.customerNameField.text
                            phone:self.customerPhoneField.text
                            email:nil
                            password:nil
                confirmationCode:self.customerCodeField.text
                      merchantId:self.customerMerchantField.text
                              extras:nil

     completionHandler:^(BOOL success, NSDictionary *response, GGCustomer *customer, NSError *error) {
         //
         
         
         UIAlertView *alertView;
         
         if (customer) {
             
             alertView = [[UIAlertView alloc] initWithTitle:nil message:[NSString stringWithFormat:@"%@ Signed in", customer.name] delegate:nil cancelButtonTitle:@"Ok" otherButtonTitles:nil];
             
             [alertView show];
             
             if (!self.trackerManager) {
                 // once we have a customer token we can activate the tracking manager
                 [GGTrackerManager trackerWithCustomerToken:customer.customerToken
                                          andDeveloperToken:kBringgDeveloperToken
                                                andDelegate:self
                                             andHTTPManager:self.httpManager];
                 // then we can access the tracker singelton via his conveninence initialiser
                 self.trackerManager = [GGTrackerManager tracker];
                
             }else{
                 [self.trackerManager setHTTPManager:self.httpManager];
                 [self.trackerManager setRealTimeDelegate:self];
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
    [self.httpManager getSharedLocationByUUID:self.shareUUIDField.text extras:nil withCompletionHandler:^(BOOL success, NSDictionary * response, GGSharedLocation *sharedLocation, NSError *error) {
        //
        
        if (success && sharedLocation) {
           
            // before calling the rate with the rating url we should strip the scheme (the http manager will add the correct scheme according to ssl configurations
            
            NSString *trueRatingURL = self.ratingURLField.text;
            trueRatingURL = [trueRatingURL stringByReplacingOccurrencesOfString:@"https://" withString:@""];
            trueRatingURL = [trueRatingURL stringByReplacingOccurrencesOfString:@"http://" withString:@""];
            
            [self.httpManager rate:[self.customerRatingField.text intValue]
                         withToken:sharedLocation.rating.token
                         ratingURL:trueRatingURL
                            extras:nil
             withCompletionHandler:^(BOOL success,NSDictionary *response,  GGRating *rating, NSError *error) {
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


#pragma mark - Helpers

- (GGOrder *)updateMonitoredOrderWithOrder:(GGOrder *)order{
    
    GGOrder *monitoredOrder = [_monitoredOrders objectForKey:order.uuid];
    if (!monitoredOrder) {
        monitoredOrder = order;
        [_monitoredOrders setObject:monitoredOrder forKey:order.uuid];
    }else{
        [monitoredOrder update:order];
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
    [self updateUIWithShared:monitoredOrder.sharedLocation.locationUUID ? monitoredOrder.sharedLocation.locationUUID : monitoredOrder.sharedLocationUUID andRatingURL:monitoredOrder.sharedLocation.ratingURL andDriver:driver.uuid andOrder:order];
}

- (void)orderDidAcceptWithOrder:(GGOrder *)order withDriver:(GGDriver *)driver{
    
    GGOrder *monitoredOrder = [self updateMonitoredOrderWithOrder:order];
    self.orderLabel.text = [NSString stringWithFormat:@"Order accepted %@ for driver %@", order.uuid, driver.uuid];
    [self updateUIWithShared:monitoredOrder.sharedLocation.locationUUID ? monitoredOrder.sharedLocation.locationUUID : monitoredOrder.sharedLocationUUID andRatingURL:monitoredOrder.sharedLocation.ratingURL andDriver:driver.uuid andOrder:order];
}

- (void)orderDidStartWithOrder:(GGOrder *)order withDriver:(GGDriver *)driver{
    
    GGOrder *monitoredOrder = [self updateMonitoredOrderWithOrder:order];
    self.orderLabel.text = [NSString stringWithFormat:@"Order started %@ for driver %@", order.uuid, driver.uuid];
     [self updateUIWithShared:monitoredOrder.sharedLocation.locationUUID ? monitoredOrder.sharedLocation.locationUUID : monitoredOrder.sharedLocationUUID andRatingURL:monitoredOrder.sharedLocation.ratingURL andDriver:driver.uuid andOrder:order];
}

- (void)orderDidArrive:(GGOrder *)order withDriver:(GGDriver *)driver{
    
    GGOrder *monitoredOrder = [self updateMonitoredOrderWithOrder:order];
    self.orderLabel.text = [NSString stringWithFormat:@"Order arrived %@", order.uuid];
    [self updateUIWithShared:monitoredOrder.sharedLocation.locationUUID ? monitoredOrder.sharedLocation.locationUUID : monitoredOrder.sharedLocationUUID andRatingURL:monitoredOrder.sharedLocation.ratingURL andDriver:driver.uuid andOrder:order];
}

-(void)orderDidFinish:(GGOrder *)order withDriver:(GGDriver *)driver{
    
    GGOrder *monitoredOrder = [self updateMonitoredOrderWithOrder:order];
    self.orderLabel.text = [NSString stringWithFormat:@"Order finished %@", order.uuid];
    [self updateUIWithShared:monitoredOrder.sharedLocation.locationUUID ? monitoredOrder.sharedLocation.locationUUID : monitoredOrder.sharedLocationUUID andRatingURL:monitoredOrder.sharedLocation.ratingURL andDriver:driver.uuid andOrder:order];
}

- (void)orderDidCancel:(GGOrder *)order withDriver:(GGDriver *)driver{
    
    GGOrder *monitoredOrder = [self updateMonitoredOrderWithOrder:order];
    
    self.orderLabel.text = [NSString stringWithFormat:@"Order canceled %@", order.uuid];
    
    [self updateUIWithShared:monitoredOrder.sharedLocation.locationUUID ? monitoredOrder.sharedLocation.locationUUID : monitoredOrder.sharedLocationUUID andRatingURL:monitoredOrder.sharedLocation.ratingURL andDriver:driver.uuid andOrder:order];
    
}


- (void)updateUIWithShared:(NSString *)shared
              andRatingURL:(NSString *)ratingURL
                 andDriver:(NSString *)driverUUID
                  andOrder:(GGOrder *)order{
    
    self.driverField.text = driverUUID;
    self.shareUUIDField.text = shared;
    self.ratingURLField.text = ratingURL;
    
    GGWaypoint *activeWp = [[order.waypoints filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"waypointId==%@", @(order.activeWaypointId)]] firstObject];
    
    self.orderLabel.text = [NSString stringWithFormat:@"STATUS : %ld", order.status];
    
    
    if (activeWp) {
        self.waypointIdField.text = [NSString stringWithFormat:@"%ld", activeWp.waypointId] ;
        if ([activeWp ETA]) {
            self.txtETA.text = [NSString stringWithFormat:@"ETA: %@", [activeWp ETA]];
        }
    }
    
   
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



#pragma mark Waypoint Delegate

-(void)watchWaypointFailedForWaypointId:(NSNumber *)waypointId error:(NSError *)error{
    self.lblWaypointStatus.text = error.localizedDescription;
}

-(void)waypointDidUpdatedWaypointId:(NSNumber *)waypointId eta:(NSDate *)eta{
    self.lblWaypointStatus.text = @"Waypoint Updated ";
    self.txtETA.text = [NSString stringWithFormat:@"ETA: %@", eta];
}

- (void)waypointDidArrivedWaypointId:(NSNumber *)waypointId{
     self.lblWaypointStatus.text = @"Waypoint arrived ";
}

- (void)waypointDidFinishedWaypointId:(NSNumber *)waypointId{
    self.lblWaypointStatus.text = @"Waypoint done ";
}



@end
