//
//  APIClient.m
//  libhypem
//
//  Created by Zane Shannon on 10/23/14.
//
//

#import "APIClient.h"
#import "User.h"

#define kBaseURLAddress @"https://api.hypem.com/"
#define kAuthCookieName @"AUTH"
#define kCookieDomain @"http://hypem.com"
#define kMaxConcurrentConnections 15
#define kLoginAction @"%@/inc/user_action"

@interface APIClient()

@property (nonatomic, retain) NSOperationQueue *queue;

+ (NSHTTPCookie *)getCookie;

@end

@implementation APIClient

- (instancetype)init {
	if (self = [super init]) {
		self.queue = [[NSOperationQueue alloc] init];
		[self.queue setMaxConcurrentOperationCount:kMaxConcurrentConnections];
	}
	
	return self;
}

#pragma mark - Authorization

- (void)loginWithUsername:(NSString *)username andPassword:(NSString *)password completion:(void (^)(User *, NSError *))completion {
	NSString *urlPath = [NSString stringWithFormat:kLoginAction, kBaseURLAddress];
	NSHTTPCookie *cookie = [APIClient getCookie];
	if (cookie == nil) {
		NSError *error = [NSError errorWithDomain:@"com.zaneshannon.hypem" code:1 userInfo:@{@"message": @"couldn't get a cookie from hypem.com"}];
		completion(nil, error);
		return;
	}
	// This is how we extract a session id from the cookie.. reverse engineered from hypem's JS
	NSString *authCookie = [cookie.value stringByReplacingPercentEscapesUsingEncoding:NSASCIIStringEncoding];
	NSArray *authCookieArray = [authCookie componentsSeparatedByString:@":"];
	NSString *session_id = authCookieArray[1];
	// This is the contstruction the auth checker expects
	NSString *bodyString = [NSString stringWithFormat:@"act=login&session=%@&user_screen_name=%@&user_password=%@", session_id, username, password];
	NSData *bodyData = [bodyString dataUsingEncoding:NSUTF8StringEncoding];
	
	NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:[NSURL URLWithString:urlPath] cachePolicy:NSURLRequestReloadIgnoringCacheData timeoutInterval:10];
	[request setHTTPShouldHandleCookies:NO];
	[request setHTTPMethod:@"POST"];
	[request setValue:@"application/x-www-form-urlencoded; charset=UTF-8" forHTTPHeaderField:@"Content-Type"]; // Critical
	[request setHTTPBody:bodyData];
	
	// Start the Operation
	Operation *operation = [[Operation alloc] init];
	operation.urlRequest = request;
	__block Operation *blockOperation = operation;
	operation.completionBlock = ^{
		if (blockOperation.responseData) {
			// Now attempt part 3
			NSString *responseString = [[NSString alloc] initWithData:blockOperation.responseData encoding:NSUTF8StringEncoding];
			if (responseString) {
				NSError *error = nil;
				id object = [NSJSONSerialization
							 JSONObjectWithData:[responseString dataUsingEncoding:NSUTF8StringEncoding]
							 options:0
							 error:&error];
				if (error) {
					error = [NSError errorWithDomain:@"com.zaneshannon.hypem" code:2 userInfo:@{@"message": @"hypem returned invalid JSON on auth"}];
					completion(nil, error);
					return;
				}
				if ([[object valueForKey:@"status"] isEqualToString:@"ok"]) {
					// Login Succeded
					dispatch_async(dispatch_get_main_queue(), ^{
						User *user = [[User alloc] init];
						completion(user, nil);
					});
				}
				else {
					// Login failed, probably invalid password
					dispatch_async(dispatch_get_main_queue(), ^{
						NSError *error = [NSError errorWithDomain:@"com.zaneshannon.hypem" code:3 userInfo:@{@"message": @"invalid username or password"}];
						completion(nil, error);
					});
				}
			}
			else {
				dispatch_async(dispatch_get_main_queue(), ^{
					NSError *error = [NSError errorWithDomain:@"com.zaneshannon.hypem" code:4 userInfo:@{@"message": @"could not parse response from hypem"}];
					completion(nil, error);
				});
			}
		}
		else {
			dispatch_async(dispatch_get_main_queue(), ^{
				NSError *error = [NSError errorWithDomain:@"com.zaneshannon.hypem" code:4 userInfo:@{@"message": @"got no response from hypem"}];
				completion(nil, error);
			});
		}
	};
	[self.queue addOperation:operation];
}

+ (void) clearCookies {
	[[NSHTTPCookieStorage sharedHTTPCookieStorage] deleteCookie:[APIClient getCookie]];
}

#pragma mark - Manage Requests
- (void)cancelAllRequests {
	for (Operation *operation in self.queue.operations) {
		[operation cancel];
	}
}

#pragma mark - Private Methods

+ (NSHTTPCookie *)getCookie {
	NSArray *cookieArray = [[NSHTTPCookieStorage sharedHTTPCookieStorage] cookiesForURL:[NSURL URLWithString:kCookieDomain]];
	if (cookieArray.count > 0) {
		for (NSHTTPCookie *cookie in cookieArray) {
			if ([cookie.name isEqualToString:kAuthCookieName]) {
				return cookie;
			}
		}
	}
	return nil;
}

@end

#pragma mark - Operation
@implementation Operation

#pragma mark - Set URL Path
-(void)setUrlPath:(NSString *)path data:(NSData *)data cookie:(NSHTTPCookie *)cookie completion:(void (^)(void))block {
	if (data) {
		self.bodyData = data;
	}
	if (self.bodyData) {
		self.urlRequest = [Operation newJSONRequestWithURL:[NSURL URLWithString:path] bodyData:self.bodyData cookie:cookie];
	}
	else {
		self.urlRequest = [Operation newGetRequestForURL:[NSURL URLWithString:path] cookie:cookie];
	}
	[self setCompletionBlock:block];
}

#pragma mark - Background
-(BOOL)isConcurrent {
	return YES;
}

#pragma mark - Main Run Loop
-(void)main {
	// Execute
	NSError *error;
	NSHTTPURLResponse *response = [[NSHTTPURLResponse alloc] init];
	self.responseData = [NSURLConnection sendSynchronousRequest:self.urlRequest returningResponse:&response error:&error];
	self.response = response;
}

#pragma mark - URL Request Building
+(NSMutableURLRequest *)newGetRequestForURL:(NSURL *)url cookie:(NSHTTPCookie *)cookie {
	NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:url cachePolicy:NSURLRequestReloadIgnoringCacheData timeoutInterval:10];
	[request setHTTPShouldHandleCookies:NO];
	[request setHTTPMethod:@"GET"];
	[request setAllHTTPHeaderFields:@{@"Content-Type": @"application/x-www-form-urlencoded; charset=UTF-8"}];
	if (cookie) {
		NSDictionary *headers = [NSHTTPCookie requestHeaderFieldsWithCookies:@[cookie]];
		[request setAllHTTPHeaderFields:headers];
	}
	return request;
}

+(NSMutableURLRequest *)newJSONRequestWithURL:(NSURL *)url bodyData:(NSData *)bodyData cookie:(NSHTTPCookie *)cookie {
	NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:url];
	[request setHTTPMethod:@"POST"];
	[request setAllHTTPHeaderFields:@{@"Content-Type": @"application/x-www-form-urlencoded; charset=UTF-8"}];
	//[request setValue:@"application/x-www-form-urlencoded" forHTTPHeaderField:@"Content-Type"];
	//[request setValue:@(bodyData.length) forKey:@"Content-Length"];
	[request setHTTPBody:bodyData];
	[request setHTTPShouldHandleCookies:YES];
	[request setCachePolicy:NSURLRequestReloadIgnoringCacheData];
	[request setAllHTTPHeaderFields:@{}];
	if (cookie) {
		NSDictionary *headers = [NSHTTPCookie requestHeaderFieldsWithCookies:@[cookie]];
		[request setAllHTTPHeaderFields:headers];
	}
	return request;
}

@end