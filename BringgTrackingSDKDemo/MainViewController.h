//
//  ViewController.h
//  BringgTrackingSDKDemo
//
//  Created by Matan Poreh on 12/17/14.
//  Copyright (c) 2014 Matan Poreh. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "GGTrackerManager.h"
#import "GGHTTPClientManager.h"
#import "BringgGlobals.h"
#import "AddOrderViewController.h"

@interface MainViewController : UIViewController <RealTimeDelegate, OrderDelegate, DriverDelegate, WaypointDelegate, AddOrderDelegate>
@property (weak, nonatomic) IBOutlet UITextField *customerTokenField;
@property (weak, nonatomic) IBOutlet UILabel *connectionLabel;
@property (weak, nonatomic) IBOutlet UIButton *connectionButton;
@property (weak, nonatomic) IBOutlet UILabel *orderLabel;
@property (weak, nonatomic) IBOutlet UITextField *orderField;

@property (weak, nonatomic) IBOutlet UITextField *orderCompoundField;

@property (weak, nonatomic) IBOutlet UIButton *orderButton;
@property (weak, nonatomic) IBOutlet UILabel *driverLabel;
@property (weak, nonatomic) IBOutlet UITextField *driverField;
@property (weak, nonatomic) IBOutlet UIButton *driverButton;
@property (weak, nonatomic) IBOutlet UITextField *shareUUIDField;
@property (weak, nonatomic) IBOutlet UITextField *ratingURLField;
@property (weak, nonatomic) IBOutlet UILabel *customerSigninLabel;
@property (weak, nonatomic) IBOutlet UIButton *addOrder;
@property (weak, nonatomic) IBOutlet UITextField *customerNameField;
@property (weak, nonatomic) IBOutlet UITextField *customerPhoneField;
@property (weak, nonatomic) IBOutlet UITextField *customerCodeField;
@property (weak, nonatomic) IBOutlet UITextField *customerMerchantField;
@property (weak, nonatomic) IBOutlet UITextField *customerRatingField;
@property (weak, nonatomic) IBOutlet UIButton *signinButton;
@property (weak, nonatomic) IBOutlet UIButton *ratingButton;
@property (weak, nonatomic) IBOutlet UILabel *lblWaypointStatus;
@property (weak, nonatomic) IBOutlet UITextField *waypointIdField;
@property (weak, nonatomic) IBOutlet UIButton *monitorWPButton;
@property (weak, nonatomic) IBOutlet UITextField *txtETA;



- (IBAction)connect:(id)sender;
- (IBAction)monitorOrder:(id)sender;
- (IBAction)monitorDriver:(id)sender;
- (IBAction)signin:(id)sender;
- (IBAction)rate:(id)sender;
- (IBAction)addOrder:(id)sender;
- (IBAction)monitorWaypoint:(id)sender;

@end

