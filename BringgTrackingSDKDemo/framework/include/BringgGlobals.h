//
//  BringgGlobals.h
//  BringgTracking
//
//  Created by Matan on 6/25/15.
//  Copyright (c) 2015 Matan Poreh. All rights reserved.
//

#ifndef BringgTracking_BringgGlobals_h
#define BringgTracking_BringgGlobals_h

#define SDK_VERSION @"1.7.7.5"
//-----------------------------------------------------------------------------

#define PARAM_STATUS @"status"
#define PARAM_CUSTOMER @"customer"
#define PARAM_CUSTOMER_ID @"customer_id"
#define PARAM_ORDER_ID @"task_id"
#define PARAM_ORDER_UUID @"order_uuid"
#define PARAM_MERCHANT_ID @"merchant_id"
#define PARAM_DRIVER @"driver"
#define PARAM_DRIVER_ID @"driver_id"
#define PARAM_DRIVER_UUID @"driver_uuid"
#define PARAM_SHARE_UUID @"share_uuid"
#define PARAM_WAY_POINT_ID @"way_point_id"
#define PARAM_ID @"id"
#define PARAM_ADDRESS @"address"
#define PARAM_UUID @"uuid"
#define PARAM_NAME @"name"
#define PARAM_EMAIL @"email"
#define PARAM_PHONE @"phone"
#define PARAM_FACEBOOK_ID @"facebook_id"
#define PARAM_IMAGE @"image"
#define PARAM_LAT @"lat"
#define PARAM_LNG @"lng"
#define PARAM_CURRENT_LAT @"current_lat"
#define PARAM_CURRENT_LNG @"current_lng"
#define PARAM_ACTIVITY @"activity"
#define PARAM_DRIVER_ACTIVITY @"driver_activity"
#define PARAM_DRIVER_AVG_RATING @"average_rating"
#define PARAM_DRIVER_AVG_RATING_IN_SHARED_LOCATION @"driver_average_rating"
#define PARAM_DRIVER_IMAGE_URL @"profile_image"
#define PARAM_DRIVER_IMAGE_URL2 @"employee_image"
#define PARAM_DRIVER_PHONE @"employee_phone"

#define PARAM_SHARED_LOCATION @"shared_location"
#define PARAM_WAYPOINTS @"way_points"
#define PARAM_TASK_INVENTORIES @"task_inventories"
#define PARAM_RATING_URL @"rating_url"
#define PARAM_ACCESS_TOKEN @"access_token"
#define PARAM_ETA @"eta"
#define PARAM_RATING @"rating"
#define PARAM_RATING_TOKEN @"rating_token"
#define PARAM_DRIVER_NAME @"employee_name"



#define PARAM_ITEM_INVENTORY_ID @"inventory_id"
#define PARAM_ITEM_PENDING @"pending"
#define PARAM_ITEM_PRICE @"price"
#define PARAM_ITEM_QUANTITY @"quantity"
#define PARAM_ITEM_SCAN @"scan_string"

#define PARAM_FIND_ME_TOKEN @"find_me_token"
#define PARAM_FIND_ME_URL @"find_me_url"
#define PARAM_FIND_ME_ENABLED @"support_find_me"


#import "GGBringgUtils.h"

#define DEFINE_SHARED_INSTANCE_USING_BLOCK(block) \
static dispatch_once_t pred = 0; \
__strong static id _sharedObject = nil; \
dispatch_once(&pred, ^{ \
_sharedObject = block(); \
}); \
return _sharedObject;

@class GGOrder;
@class GGDriver;
@class GGCustomer;
@class GGRating;
@class GGSharedLocation;
@class GGFindMe;

@protocol OrderDelegate <NSObject>

/**
 *  notifies watch action for an order has failed
 *
 *  @param order the order requesting watch
 *  @param error failure reason
 */
- (void)watchOrderFailForOrder:(nonnull GGOrder *)order error:(nonnull NSError *)error;


/**
 *  notifies an order was assigned to a driver
 *
 *  @param order  order
 *  @param driver driver assigned
 */
- (void)orderDidAssignWithOrder:(nonnull GGOrder *)order withDriver:(nonnull GGDriver *)driver;

/**
 *  notfies an order was accepted by a certain driver
 *
 *  @param order  order
 *  @param driver accepting driver
 */
- (void)orderDidAcceptWithOrder:(nonnull GGOrder *)order withDriver:(nonnull GGDriver *)driver;


/**
 *  notifies an order is starting its course to its destination
 *
 *  @param order  order
 *  @param driver driver of order
 */
- (void)orderDidStartWithOrder:(nonnull GGOrder *)order withDriver:(nonnull GGDriver *)driver;
@optional

/**
 *  notifies an order has arrived to one of it's destinations
 *
 *  @param order  order
 *  @param driver driver of order
 */
- (void)orderDidArrive:(nonnull GGOrder *)order withDriver:(nonnull GGDriver *)driver;


/**
 *  notifies an order delivery has been completed
 *
 *  @param order  order
 *  @param driver driver of order
 */
- (void)orderDidFinish:(nonnull GGOrder *)order withDriver:(nonnull GGDriver *)driver;

/**
 *  notifies an order has been cancled
 *
 *  @param order  order
 *  @param driver driver of order
 */
- (void)orderDidCancel:(nonnull GGOrder *)order withDriver:(nullable GGDriver *)driver;

/**
 *  notifies updates for shared locations and findme configuration for specific orders
 *
 *  @param order               the order
 *  @param sharedLocation      orders shared location object
 *  @param findMeConfiguration findme configuration object
 */
- (void)order:(nonnull GGOrder *)order didUpdateLocation:(nullable GGSharedLocation *)sharedLocation findMeConfiguration:(nullable GGFindMe *)findMeConfiguration;

/**
 *  notifies that the tracker is about to revive all previously monitored orders
 *
 *  @param orderUUID uuid of order
 */
- (void)trackerWillReviveWatchedOrder:(nonnull NSString *)orderUUID;

@end

@protocol DriverDelegate <NSObject>

/**
 *  notifies if watching a driver failed
 *
 *  @param waypointId id of driver
 *  @param error      error
 */
- (void)watchDriverFailedForDriver:(nullable GGDriver *)driver error:(nonnull NSError *)error;
@optional

/**
 *  notifies a driver has changed location
 *
 *  @param driver the updated driver object
 */
- (void)driverLocationDidChangeWithDriver:(nonnull GGDriver *)driver;

/**
 *  notifies that the tracker is about to revive all previously monitored drivers
 *
 *  @param driverUUID uuid of driver
 *  @param sharedUUID uuid of shared
 */
- (void)trackerWillReviveWatchedDriver:(nonnull NSString *)driverUUID withSharedUUID:(nonnull NSString *)sharedUUID;

@end

@protocol WaypointDelegate <NSObject>
/**
 *  notifies if watching a waypoint failed
 *
 *  @param waypointId id of waypoint
 *  @param error      error
 */
- (void)watchWaypointFailedForWaypointId:(nonnull NSNumber *)waypointId error:(nonnull NSError *)error;
@optional

/**
 *  notifies ETA updates to a waypoint
 *
 *  @param waypointId id of waypoint
 *  @param eta        ETA
 */
- (void)waypointDidUpdatedWaypointId:(nonnull NSNumber *)waypointId eta:(nullable NSDate *)eta;


/**
 *  notifies a driver has arrvied a waypoint
 *
 *  @param waypointId id of waypoint
 */
- (void)waypointDidArrivedWaypointId:(nonnull NSNumber *)waypointId;

/**
 *  notifies a waypoint has finished
 *
 *  @param waypointId id of waypoint
 */
- (void)waypointDidFinishedWaypointId:(nonnull NSNumber *)waypointId;

/**
 *  notifies that the tracker is about to revive all previously monitored waypoints
 *
 *  @param waypointId id of waypoint
 */
- (void)trackerWillReviveWatchedWaypoint:(nonnull NSNumber *)waypointId;

@end

typedef void (^GGActionResponseHandler)(BOOL success, NSError * _Nullable error);

typedef void (^GGNetworkResponseHandler)(BOOL success, id _Nullable JSON, NSError * _Nullable error);

typedef void (^GGCustomerResponseHandler)(BOOL success, NSDictionary * _Nullable response,  GGCustomer * _Nullable customer, NSError * _Nullable error);

typedef void (^GGOrderResponseHandler)(BOOL success, NSDictionary * _Nullable response,GGOrder * _Nullable order, NSError *_Nullable error);

typedef void (^GGSharedLocationResponseHandler)(BOOL success, NSDictionary * _Nullable response, GGSharedLocation * _Nullable sharedLocation, NSError * _Nullable error);

typedef void (^GGRatingResponseHandler)(BOOL success, NSDictionary * _Nullable response, GGRating * _Nullable rating, NSError * _Nullable error);

typedef NS_ENUM(NSInteger, OrderStatus) {
    OrderStatusInvalid = -1,
    OrderStatusCreated = 0,
    OrderStatusAssigned = 1,
    OrderStatusOnTheWay = 2,
    OrderStatusCheckedIn = 3,
    OrderStatusDone = 4,
    OrderStatusAccepted = 6,
    OrderStatusCancelled = 7,
    OrderStatusRejected = 8,
    OrderStatusRemotelyDeleted = 200
    
};

typedef NS_ENUM(NSInteger, GGErrorType) {
    GGErrorTypeUnknown = -1,
    GGErrorTypeNone = 0,
    GGErrorTypeUUIDNotFound = 1,
    GGErrorTypeInvalidUUID = 2,
    GGErrorTypeActionNotAllowed = 3,
    GGErrorTypeOrderNotFound = 4,
    GGErrorTypeHTTPManagerNotSet = 5,
    GGErrorTypeTrackerNotSet = 6,
};

#endif
