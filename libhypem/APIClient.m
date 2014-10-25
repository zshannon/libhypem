//
//  APIClient.m
//  libhypem
//
//  Created by Zane Shannon on 10/23/14.
//
//

#import "APIClient.h"

#define kBaseURLAddress @"https://api.hypem.com/"
#define kAuthCookieName @"AUTH"
#define kCookieDomain @"http://hypem.com"
#define kMaxConcurrentConnections 15
#define kLoginAction @"%@/inc/user_action"

@interface APIClient()

@property (nonatomic, retain) NSOperationQueue *queue;

@end

@implementation APIClient

- (instancetype)init {
	if (self = [super init]) {
		self.queue = [[NSOperationQueue alloc] init];
		[self.queue setMaxConcurrentOperationCount:kMaxConcurrentConnections];
	}
	
	return self;
}

- (void)loginWithUsername:(NSString *)username andPassword:(NSString *)password andCookie:(NSHTTPCookie*)cookie completion:(LoginCompletion)completion {
	// Now let's attempt to login
	NSString *urlPath = [NSString stringWithFormat:kLoginAction, kBaseURLAddress];
	
	// Build the body data
	NSString *authCookie = [cookie.value stringByReplacingPercentEscapesUsingEncoding:NSASCIIStringEncoding];
	NSArray *authCookieArray = [authCookie componentsSeparatedByString:@":"];
	// TODO: get session off Cookie
	NSString *session = authCookieArray[1];
	NSString *bodyString = [NSString stringWithFormat:@"act=login&session=%@&user_screen_name=%@&user_password=%@", session, username, password];
	NSData *bodyData = [bodyString dataUsingEncoding:NSUTF8StringEncoding];
	
	NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:[NSURL URLWithString:urlPath] cachePolicy:NSURLRequestReloadIgnoringCacheData timeoutInterval:10];
	[request setHTTPShouldHandleCookies:NO];
	[request setHTTPMethod:@"POST"];
	[request setValue:@"application/x-www-form-urlencoded; charset=UTF-8" forHTTPHeaderField:@"Content-Type"];
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
				if ([responseString rangeOfString:[@"'status':'ok'" stringByReplacingOccurrencesOfString:@"'" withString:@"\""]].location > 0) {
					// Login Succeded
					dispatch_async(dispatch_get_main_queue(), ^{
						completion(YES, nil, nil);
					});
				}
				else {
					// Login failed
					dispatch_async(dispatch_get_main_queue(), ^{
						completion(NO, nil, nil);
					});
				}
			}
			else {
				dispatch_async(dispatch_get_main_queue(), ^{
					completion(NO, nil,nil);
				});
			}
		}
		else {
			dispatch_async(dispatch_get_main_queue(), ^{
				completion(NO, nil,nil);
			});
		}
	};
	[self.queue addOperation:operation];
}

- (void)validateAndSetSessionWithCookie:(NSHTTPCookie *)cookie completion:(LoginCompletion)completion {
	// And finally we attempt to create the User
	// Build URL String
	NSString *urlPath = [NSString stringWithFormat:@"%@user?id=pg", kBaseURLAddress];
	
	// Start the Operation
	Operation *operation = [[Operation alloc] init];
	__block Operation *blockOperation = operation;
	[operation setUrlPath:urlPath data:nil cookie:cookie completion:^{
		if (blockOperation.responseData) {
			// Now attempt part 3
			NSString *html = [[NSString alloc] initWithData:blockOperation.responseData encoding:NSUTF8StringEncoding];
			if (html) {
				if ([html rangeOfString:@"<a href=\"logout"].location != NSNotFound) {
					NSScanner *scanner = [[NSScanner alloc] initWithString:html];
					NSString *trash = @"", *userString = @"", *karma=@"";
					[scanner scanUpToString:@"<a href=\"threads?id=" intoString:&trash];
					[scanner scanString:@"<a href=\"threads?id=" intoString:&trash];
					[scanner scanUpToString:@"\">" intoString:&userString];
					[scanner scanUpToString:@"&nbsp;(" intoString:&trash];
					[scanner scanString:@"&nbsp;(" intoString:&trash];
					[scanner scanUpToString:@")" intoString:&karma];
					//[self getLoggedInUser:userString karma:[karma intValue] completion:completion];
				}
				else {
					dispatch_async(dispatch_get_main_queue(), ^{
						completion(NO, nil, nil);
					});
				}
			}
			else {
				dispatch_async(dispatch_get_main_queue(), ^{
					completion(NO, nil, nil);
				});
			}
		}
		else {
			dispatch_async(dispatch_get_main_queue(), ^{
				completion(NO, nil, nil);
			});
		}
	}];
	[self.queue addOperation:operation];
}

#pragma mark - Manage Requests
- (void)cancelAllRequests {
	for (Operation *operation in self.queue.operations) {
		[operation cancel];
	}
}

#pragma mark - Cookie

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