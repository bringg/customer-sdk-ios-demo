//
//  ViewController.h
//  BringgTrackingSDKDemo
//
//  Created by Ilya Kalinin on 12/17/14.
//  Copyright (c) 2014 Ilya Kalinin. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "BringgTracker.h"

@interface ViewController : UIViewController <RealTimeDelegate, OrderDelegate, DriverDelegate>
@property (weak, nonatomic) IBOutlet UILabel *connectionLabel;
@property (weak, nonatomic) IBOutlet UIButton *connectionButton;
@property (weak, nonatomic) IBOutlet UILabel *orderLabel;
@property (weak, nonatomic) IBOutlet UITextField *orderField;
@property (weak, nonatomic) IBOutlet UIButton *orderButton;
@property (weak, nonatomic) IBOutlet UILabel *driverLabel;
@property (weak, nonatomic) IBOutlet UITextField *driverField;
@property (weak, nonatomic) IBOutlet UIButton *driverButton;
@property (weak, nonatomic) IBOutlet UITextField *uuidField;

- (IBAction)connect:(id)sender;
- (IBAction)monitorOrder:(id)sender;
- (IBAction)monitorDriver:(id)sender;

@end

