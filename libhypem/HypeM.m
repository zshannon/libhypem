//
//  HypeM.m
//  libhypem
//
//  Created by Zane Shannon on 10/23/14.
//
//

#import "HypeM.h"
#import "APIClient.h"
#import "User.h"
#import "Playlist.h"

@interface HypeM()

@property (strong, nonatomic) User *user;

@end

@implementation HypeM

NSString *const HMUserAuthenticationChangedNotification = @"HMUserAuthenticationChangedNotification";

// Build the static manager object
static HypeM * _sharedInstance = nil;

#pragma mark - Check for Logged In User
- (BOOL) userIsLoggedIn {
	return self.user != nil;
}

#pragma mark - Authentication Methods
- (void)loginWithUsername:(NSString *)username andPassword:(NSString *)password andCompletion:(void (^)(User *, NSError *))completion{
	__weak typeof(self) wSelf = self;
	[self.client loginWithUsername:username andPassword:password completion:^(User *user, NSError *error) {
		if (error == nil) {
			wSelf.user = user;
			// Post Notification
			[[NSNotificationCenter defaultCenter] postNotificationName:HMUserAuthenticationChangedNotification object:user];
		}
		else {
			[[NSNotificationCenter defaultCenter] postNotificationName:HMUserAuthenticationChangedNotification object:error];
		}
		completion(user, error);
	}];
}

- (void)logout {
	[APIClient clearCookies];
	self.user = nil;
	[[NSNotificationCenter defaultCenter] postNotificationName:HMUserAuthenticationChangedNotification object:nil];
}

#pragma mark - Set Up HypeM's Singleton
+ (HypeM *) sharedInstance {
	@synchronized([HypeM class]) {
		if (!_sharedInstance)
			_sharedInstance  = [[HypeM alloc] init];
		return _sharedInstance;
	}
	return nil;
}

+ (id) alloc {
	@synchronized([HypeM class]) {
		NSAssert(_sharedInstance == nil, @"Attempted to allocate a second instance of a singleton.");
		_sharedInstance = [super alloc];
		return _sharedInstance;
	}
	return nil;
}

- (instancetype) init {
	if (self = [super init]) {
		// Set up APIClient
		self.client = [[APIClient alloc] init];
	}
	return self;
}

@end
