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

typedef void (^LoginCompletion) (bool success, NSHTTPCookie *cookie, NSError *error);

#pragma mark - Singleton Manager
/**
 This is the singleton object that all of your HypeM API calls will go through.
 */
+ (HypeM *)sharedInstance;

#pragma mark - Session
/**
 This is the ideal method to start the HypeM session. It attempts to find a cookie and log a user in if it does find one. You should call this method in the AppDelegate.
 */
- (void)startSession;

/**
 Determines if a user is currently logged in or not.
 @return    BOOL for YES a user is logged in.
 */
- (BOOL)userIsLoggedIn;

#pragma mark - APIClient Methods
/**
 Attempts to login to HypeM with a username and password.
 @param user   - HypeM username
 @param pass   - HypeM password
 @return    User in the completion block if successful
 */
- (void)loginWithUsername:(NSString *)username andPassword:(NSString *)password completion:(LoginCompletion)completion;

/**
 Ends the current HypeM session, and destroys the cookie
 */
- (void)logout;

@end
