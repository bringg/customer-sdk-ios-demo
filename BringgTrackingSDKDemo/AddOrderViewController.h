//
//  AddOrderViewController.h
//  BringgTrackingSDKDemo
//
//  Created by Matan on 6/30/15.
//  Copyright (c) 2015 Matan Poreh. All rights reserved.
//

#import <UIKit/UIKit.h>

@class GGOrderBuilder;
@class AddOrderViewController;

@protocol AddOrderDelegate <NSObject>

-(void)orderBuilderDidCreate:(GGOrderBuilder *)orderBuilder withController:(AddOrderViewController *)controller;

@end

@interface AddOrderViewController : UIViewController
@property (weak, nonatomic) IBOutlet UITextField *orderTitleInputField;
@property (weak, nonatomic) IBOutlet UITextField *waypointAddressInputField;
@property (weak, nonatomic) IBOutlet UITextField *waypointCustomerPhoneInputField;
@property (weak, nonatomic) IBOutlet UILabel *waypointsTitleLabel;

@property (weak, nonatomic) id<AddOrderDelegate> delegate;


- (void)setOrderDelegate:(id<AddOrderDelegate>)delegate;

- (IBAction)settitle:(id)sender;
- (IBAction)addWaypoint:(id)sender;
- (IBAction)closeAndSend:(id)sender;

@end
