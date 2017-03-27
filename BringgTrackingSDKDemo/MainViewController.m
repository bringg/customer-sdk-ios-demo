//
//  ViewController.m
//  BringgTrackingSDKDemo
//
//  Created by Matan Poreh on 12/17/14.
//  Copyright (c) 2014 Matan Poreh. All rights reserved.
//

#import "MainViewController.h"

#define kBringgDeveloperToken @"{YOUR_DEV_ACCESS_TOKEN}"

#define ARC4RANDOM_MAX      0x100000000




@interface MainViewController ()


@property (nonatomic, strong) BringgTrackingClient *trackingClient;
@property (nonatomic, strong) NSMutableDictionary *monitoredOrders;
@property (nonatomic, strong) NSMutableDictionary *monitoredWaypoints;

@property (nonatomic, strong) GGOrder *currentMonitoredOrder;

@end

@implementation MainViewController

- (id)initWithCoder:(NSCoder *)aDecoder {
    if (self = [super initWithCoder:aDecoder]) {
    
        self.trackingClient = [BringgTrackingClient clientWithDeveloperToken:kBringgDeveloperToken connectionDelegate:self];
    
        _monitoredOrders = [NSMutableDictionary dictionary];
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
    
    self.btnFindme.layer.masksToBounds = YES;
    self.btnFindme.layer.cornerRadius = 4.f;
    
    [self.btnFindme setEnabled:NO];
    

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
    
   
    
    if ([self.trackingClient isConnected]) {
        NSLog(@"disconnecting");
        [self.trackingClient disconnect];
    }else{
        NSLog(@"connecting to http/https");
        [self.trackingClient connect];
    }
    
    
}

- (IBAction)monitorOrder:(id)sender {

    NSString *orderuuid     = self.orderField.text;
    NSString *sharedUUID    = self.shareUUIDField.text;
    
    if (orderuuid == nil || orderuuid.length == 0 || sharedUUID == nil || sharedUUID.length == 0) {
        UIAlertView  *alertView = [[UIAlertView alloc] initWithTitle:@"General Service Error" message:@"Order UUID and Shared UUID cannot be empty" delegate:nil cancelButtonTitle:@"Ok" otherButtonTitles:nil];
        
        [alertView show];
        return;
    }
    
    // if no order object we create one with the uuid we got from the partner api and the 'Created' status
    GGOrder *order = [[GGOrder alloc] initOrderWithUUID:orderuuid atStatus:OrderStatusCreated];
    order.sharedLocationUUID = sharedUUID;
    
    [self trackOrder:order];
    
 
}


- (void)trackOrder:(GGOrder *)order{
    
    if ([self.trackingClient isWatchingOrderWithUUID:order.uuid]) {
        
        [_monitoredOrders setObject:[NSNull null] forKey:order.uuid];
        
        [self.trackingClient stopWatchingOrderWithUUID:order.uuid ];
        [self.orderButton setTitle:@"Monitor Order" forState:UIControlStateNormal];
    }else{
        
        [_monitoredOrders setObject:order forKey:order.uuid];
        
        [self.trackingClient startWatchingOrderWithUUID:order.uuid sharedUUID:order.sharedLocationUUID ?: order.sharedLocation.locationUUID delegate:self];
        [self.orderButton setTitle:@"Stop Monitor Order" forState:UIControlStateNormal];
    }
}

- (IBAction)monitorDriver:(id)sender {
    NSString *uuid = self.driverField.text;
    NSString *shareuuid = self.shareUUIDField.text;
    if (uuid && [uuid length]) {
        if ([self.trackingClient isWatchingDriverWithUUID:uuid andShareUUID:shareuuid]) {
            
            [self.trackingClient stopWatchingDriverWithUUID:uuid shareUUID:shareuuid];
            [self.driverButton setTitle:@"Monitor Driver" forState:UIControlStateNormal];
            
        } else {
            [self.trackingClient startWatchingDriverWithUUID:uuid shareUUID:shareuuid delegate:self];
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
        
        if ([self.trackingClient isWatchingWaypointWithWaypointId:wpid andOrderUUID:orderUUID]) {
           [ _monitoredWaypoints setObject:[NSNull null] forKey:wpid];
            [self.trackingClient stopWatchingWaypointWithWaypointId:wpid andOrderUUID:orderUUID];
            [self.monitorWPButton setTitle:@"Monitor Waypoint" forState:UIControlStateNormal];
        }else{
            [self.trackingClient startWatchingWaypointWithWaypointId:wpid andOrderUUID:orderUUID delegate:self];
            [self.monitorWPButton setTitle:@"Stop Monitor Waypoint" forState:UIControlStateNormal];
        }
    }
    
}

- (IBAction)onFindMe:(UIButton *)sender {
    
    //TODO: add find me button functionality
    // for the purpose of the demo we will randomize location instead of getting an actuall one
    if (!_currentMonitoredOrder) {
        return;
    }
    
    [self.btnFindme setEnabled:NO];
    
    double lat = (((double)arc4random() / ARC4RANDOM_MAX)*180) - 90;
    double lng = (((double)arc4random() / ARC4RANDOM_MAX)*360) - 180;
    
    [self.trackingClient sendFindMeRequestForOrderWithUUID:_currentMonitoredOrder.uuid latitude:lat longitude:lng withCompletionHandler:^(BOOL success, NSError * _Nullable error) {
    
        //
        __weak __typeof(&*self)weakSelf = self;
        dispatch_async(dispatch_get_main_queue(), ^{
            //
            [weakSelf.btnFindme setEnabled:YES];
            
            NSString *title;
            NSString *msg;
            
            if (error) {
                title = @"Find Me Error";
                msg = error.userInfo[NSLocalizedDescriptionKey];
            }else{
                msg = @"Find Me request sent";
            }
            
            UIAlertView  *alertView = [[UIAlertView alloc] initWithTitle:title message:msg delegate:nil cancelButtonTitle:@"Ok" otherButtonTitles:nil];
            
            [alertView show];
            
        });
        
    }];
}




- (IBAction)signin:(id)sender {
    //signin to get customer token
    
   
    
    [self.trackingClient signInWithName:self.customerNameField.text
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
             
             self.customerTokenField.text = customer.customerToken;
            
             
         }else if (error){
            alertView = [[UIAlertView alloc] initWithTitle:@"Sign in Error" message:error.localizedDescription delegate:nil cancelButtonTitle:@"Ok" otherButtonTitles:nil];
             
             [alertView show];
         }
     }];
}

- (IBAction)rate:(id)sender {
    
    int ratingValue = [self.customerRatingField.text intValue];
    if (_currentMonitoredOrder && ratingValue > 0) {
        
        [self.trackingClient rateOrder:_currentMonitoredOrder withRating:ratingValue completionHandler:^(BOOL success, NSDictionary * _Nullable response, GGRating * _Nullable rating, NSError * _Nullable error) {
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
    }else{
        NSLog(@"rating must include a valid order and rating of 1-5");
    }
    
    
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

- (void)watchOrderSucceedForOrder:(GGOrder *)order {
    GGOrder *monitoredOrder = [self updateMonitoredOrderWithOrder:order];
    
    [self updateUIWithShared:monitoredOrder.sharedLocation.locationUUID ? monitoredOrder.sharedLocation.locationUUID : monitoredOrder.sharedLocationUUID
                andRatingURL:monitoredOrder.sharedLocation.ratingURL
                   andDriver:order.driverUUID
                    andOrder:order];
}

- (void)watchOrderFailForOrder:(GGOrder *)order error:(NSError *)error{
    
    NSString *errorMessage = [NSString stringWithFormat:@"%@.\nDid you enter the correct Order UUID?", error.localizedDescription.capitalizedString];
    
   UIAlertView* alertView = [[UIAlertView alloc] initWithTitle:@"Watch Order Error" message:errorMessage delegate:nil cancelButtonTitle:@"Ok" otherButtonTitles:nil];
    
    [alertView show];
    
    self.orderLabel.text = [NSString stringWithFormat:@"Failed %@, error %@", order.uuid, error];
    [self.orderButton setTitle:@"Monitor Order" forState:UIControlStateNormal];
    self.ratingURLField.text = order.sharedLocation.ratingURL;
}

- (void)orderDidAssignWithOrder:(GGOrder *)order withDriver:(GGDriver *)driver{
    
    GGOrder *monitoredOrder = [self updateMonitoredOrderWithOrder:order];
    self.orderLabel.text = [NSString stringWithFormat:@"Order assigned %@ for driver %@", order.uuid, driver.uuid];
    [self updateUIWithShared:monitoredOrder.sharedLocation.locationUUID ? monitoredOrder.sharedLocation.locationUUID : monitoredOrder.sharedLocationUUID andRatingURL:monitoredOrder.sharedLocation.ratingURL andDriver:driver.uuid ?: order.driverUUID andOrder:order];
}

- (void)orderDidAcceptWithOrder:(GGOrder *)order withDriver:(GGDriver *)driver{
    
    GGOrder *monitoredOrder = [self updateMonitoredOrderWithOrder:order];
    self.orderLabel.text = [NSString stringWithFormat:@"Order accepted %@ for driver %@", order.uuid, driver.uuid];
    [self updateUIWithShared:monitoredOrder.sharedLocation.locationUUID ? monitoredOrder.sharedLocation.locationUUID : monitoredOrder.sharedLocationUUID andRatingURL:monitoredOrder.sharedLocation.ratingURL andDriver:driver.uuid ?: order.driverUUID andOrder:order];
}

- (void)orderDidStartWithOrder:(GGOrder *)order withDriver:(GGDriver *)driver{
    
    GGOrder *monitoredOrder = [self updateMonitoredOrderWithOrder:order];
    self.orderLabel.text = [NSString stringWithFormat:@"Order started %@ for driver %@", order.uuid, driver.uuid];
    [self updateUIWithShared:monitoredOrder.sharedLocation.locationUUID ? monitoredOrder.sharedLocation.locationUUID : monitoredOrder.sharedLocationUUID andRatingURL:monitoredOrder.sharedLocation.ratingURL andDriver:driver.uuid ?: order.driverUUID andOrder:order];
}

- (void)orderDidArrive:(GGOrder *)order withDriver:(GGDriver *)driver{
    
    GGOrder *monitoredOrder = [self updateMonitoredOrderWithOrder:order];
    self.orderLabel.text = [NSString stringWithFormat:@"Order arrived %@", order.uuid];
    [self updateUIWithShared:monitoredOrder.sharedLocation.locationUUID ? monitoredOrder.sharedLocation.locationUUID : monitoredOrder.sharedLocationUUID andRatingURL:monitoredOrder.sharedLocation.ratingURL andDriver:driver.uuid ?: order.driverUUID andOrder:order];
}

-(void)orderDidFinish:(GGOrder *)order withDriver:(GGDriver *)driver{
    
    GGOrder *monitoredOrder = [self updateMonitoredOrderWithOrder:order];
    self.orderLabel.text = [NSString stringWithFormat:@"Order finished %@", order.uuid];
    [self updateUIWithShared:monitoredOrder.sharedLocation.locationUUID ? monitoredOrder.sharedLocation.locationUUID : monitoredOrder.sharedLocationUUID andRatingURL:monitoredOrder.sharedLocation.ratingURL andDriver:driver.uuid ?: order.driverUUID andOrder:order];
}

- (void)orderDidCancel:(GGOrder *)order withDriver:(GGDriver *)driver{
    
    GGOrder *monitoredOrder = [self updateMonitoredOrderWithOrder:order];
    
    self.orderLabel.text = [NSString stringWithFormat:@"Order canceled %@", order.uuid];
    
    [self updateUIWithShared:monitoredOrder.sharedLocation.locationUUID ? monitoredOrder.sharedLocation.locationUUID : monitoredOrder.sharedLocationUUID andRatingURL:monitoredOrder.sharedLocation.ratingURL andDriver:driver.uuid ?: order.driverUUID andOrder:order];
    
}

- (void)order:(nonnull GGOrder *)order didUpdateLocation:(nullable GGSharedLocation *)sharedLocation findMeConfiguration:(nullable GGFindMe *)findMeConfiguration{
    
    NSLog(@"order with ID %ld did update shared location %@ find me configuration to %@", (long)order.orderid, sharedLocation.locationUUID , findMeConfiguration);
}


- (void)updateUIWithShared:(NSString *)shared
              andRatingURL:(NSString *)ratingURL
                 andDriver:(NSString *)driverUUID
                  andOrder:(GGOrder *)order{
    
    self.driverField.text = driverUUID;
    self.ratingURLField.text = ratingURL;
    
    GGWaypoint *activeWp = [[order.waypoints filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"waypointId==%@", @(order.activeWaypointId)]] firstObject];
    
    self.orderLabel.text = [NSString stringWithFormat:@"STATUS : %ld", (long)order.status];
    
    
    if (activeWp) {
        self.waypointIdField.text = [NSString stringWithFormat:@"%ld", (long)activeWp.waypointId] ;
        if ([activeWp ETA]) {
            self.txtETA.text = [NSString stringWithFormat:@"ETA: %@", [activeWp ETA]];
        }
    }
    
    [self.btnFindme setEnabled:order && order.sharedLocation && [order.sharedLocation canSendFindMe]];
    
    if (order) {
        self.currentMonitoredOrder = order;
    }
   
}

#pragma mark - DriverDelegate

- (void)watchDriverSucceedForDriver:(GGDriver *)driver {
    NSLog(@"Watch driver succeeded for driver: %@", driver);
}

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

- (void)watchWaypointSucceededForWaypointId:(NSNumber *)waypointId waypoint:(GGWaypoint *)waypoint {
    NSLog(@"Watch waypoint succeeded for waypoint: %@", waypoint);
}

@end
