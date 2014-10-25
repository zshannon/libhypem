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

@interface HypeM()

@property (strong, nonatomic) APIClient *client;
@property (strong, nonatomic) NSHTTPCookie *cookie;
@property (strong, nonatomic) User *user;

- (void)setCookie:(NSHTTPCookie *)cookie user:(User *)user;
- (void) validateAndSetCookieWithCompletion:(LoginCompletion)completion;

@end

@implementation HypeM

// Build the static manager object
static HypeM * _sharedInstance = nil;


#pragma mark - Set Up HNManager's Singleton
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

#pragma mark - Session
- (void) startSession {
	// Set Values from Defaults
	self.cookie = [APIClient getCookie];
	
	// Validate User/Cookie
	__weak typeof(self) wSelf = self;
	[self validateAndSetCookieWithCompletion:^(bool success, NSHTTPCookie *cookie, NSError *error) {
		if (!wSelf) {
			return;
		}
		
		__strong typeof(self) sSelf = wSelf;
		sSelf.cookie = cookie ? cookie : nil;
		
		// Post Notification
		[[NSNotificationCenter defaultCenter] postNotificationName:@"DidLoginOrOut" object:nil];
	}];
}

#pragma mark - Check for Logged In User
- (BOOL) userIsLoggedIn {
	return self.cookie && self.user;
}


#pragma mark - APIClient Methods
- (void)loginWithUsername:(NSString *)username andPassword:(NSString *)password completion:(LoginCompletion)completion {
	__weak typeof(self) wSelf = self;
	[self.client loginWithUsername:username andPassword:password andCookie:self.cookie completion:^(bool success, NSHTTPCookie *cookie, NSError *error) {
		if (username && cookie && wSelf) {
			// Set Cookie & User
			//[sSelf setCookie:cookie user:user];
			
			// Post Notification
			[[NSNotificationCenter defaultCenter] postNotificationName:@"DidLoginOrOut" object:username];
			
			// Pass user on through
			completion(success, cookie, error);
		}
		else {
			completion(success, cookie, error);
		}
	}];
}

- (void)logout {
	// Delete cookie from Storage
	[[NSHTTPCookieStorage sharedHTTPCookieStorage] deleteCookie:self.cookie];
	
	// Delete objects in memory
	self.cookie = nil;
	self.user = nil;
	
	// Post Notification
	[[NSNotificationCenter defaultCenter] postNotificationName:@"DidLoginOrOut" object:nil];
}

- (void)setCookie:(NSHTTPCookie *)cookie user:(User *)user {
	self.user = user;
	self.cookie = cookie;
}

- (void) validateAndSetCookieWithCompletion:(LoginCompletion)completion {
	NSHTTPCookie *cookie = [APIClient getCookie];
	if (cookie) {
		[self.client validateAndSetSessionWithCookie:cookie completion:completion];
	}
}

@end
