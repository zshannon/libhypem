//
//  HypeM.h
//  libhypem
//
//  Created by Zane Shannon on 10/23/14.
//
//

#import <Foundation/Foundation.h>

@class APIClient, User;

@interface HypeM : NSObject

extern NSString *const HMUserAuthenticationChangedNotification;

#pragma mark - Singleton Manager
/**
 This is the singleton object that all of your HypeM API calls will go through.
 */
+ (HypeM *)sharedInstance;

/**
 Determines if a user is currently logged in or not.
 @return    BOOL for YES a user is logged in.
 */
- (BOOL)userIsLoggedIn;

#pragma mark - Authentication Methods
/**
 Attempts to login to HypeM with a username and password.
 @param user   - HypeM username
 @param pass   - HypeM password
 */
- (void)loginWithUsername:(NSString *)username andPassword:(NSString *)password andCompletion:(void (^)(User *, NSError *))completion;

/**
 Ends the current HypeM session, and destroys the cookie
 */
- (void)logout;

@end
