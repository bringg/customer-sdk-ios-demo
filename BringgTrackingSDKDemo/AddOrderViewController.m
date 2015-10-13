//
//  AddOrderViewController.m
//  BringgTrackingSDKDemo
//
//  Created by Matan on 6/30/15.
//  Copyright (c) 2015 Matan Poreh. All rights reserved.
//

#import "AddOrderViewController.h"
#import "GGOrderBuilder.h"

#define ARC4RANDOM_MAX      0x100000000

@interface AddOrderViewController ()

@property (nonatomic, strong) GGOrderBuilder *orderBuilder;


@end

@implementation AddOrderViewController


- (void)viewDidLoad{
    
    // init an order build object
    _orderBuilder = [[GGOrderBuilder alloc] init];
    
    
}

- (void)viewWillAppear:(BOOL)animated{
    
}


- (void)setOrderDelegate:(id<AddOrderDelegate>)delegate{
    _delegate = delegate;
}
- (IBAction)settitle:(id)sender {
    
    [_orderBuilder setTitle:_orderTitleInputField.text];
}

- (IBAction)addWaypoint:(id)sender {
    
    
    // we must have phone and address
    if (!_waypointAddressInputField.text || !_waypointCustomerPhoneInputField.text) {
        
        _waypointsTitleLabel.text = @"waypoint must have name and address";
        
        return;
    }
    
    double lat = ((double)arc4random() / ARC4RANDOM_MAX)* 60;
    double lng = ((double)arc4random() / ARC4RANDOM_MAX)* 60;
    
   _orderBuilder =  [_orderBuilder addWaypointAtLatitude:lat
                               longitude:lng
                                 address:_waypointAddressInputField.text
                                   phone:_waypointCustomerPhoneInputField.text
                                   email:nil
                                   notes:nil];
    
    _waypointsTitleLabel.text = [NSString stringWithFormat:@"Waypoints: %lu", (unsigned long)_orderBuilder.numWaypoints];
    
}

- (IBAction)closeAndSend:(id)sender {
    
    [self.presentingViewController dismissViewControllerAnimated:YES completion:^{
        //
        if (_delegate && [_delegate respondsToSelector:@selector(orderBuilderDidCreate:withController:)]) {
            [_delegate orderBuilderDidCreate:_orderBuilder withController:self];
        }
    }];
    
}
@end
