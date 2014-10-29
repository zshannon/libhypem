//
//  APIClient.m
//  libhypem
//
//  Created by Zane Shannon on 10/23/14.
//
//

#import "APIClient.h"
#import "Playlist.h"
#import "User.h"
#import "Track.h"

#define kBaseAPIAddress @"https://api.hypem.com"
#define kBaseWebAddress @"http://hypem.com"
#define kAuthCookieName @"AUTH"
#define kCookieDomain @"http://hypem.com"
#define kMaxConcurrentConnections 15

#define kLoginAction @"%@/inc/user_action"
#define kPlaylistAction @"%@/playlist/:type/:arg/json/:page"
#define kPlaylistHTMLAction @"%@/:type/:arg/:page"
#define kTrackDownloadAction @"%@/serve/source/:mediaid/:key"
#define kUserProfileAction @"%@/api/get_profile?username=:username"

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
	NSString *urlPath = [NSString stringWithFormat:kLoginAction, kBaseAPIAddress];
	NSHTTPCookie *cookie = [APIClient getCookie];
	if (cookie == nil) {
		NSError *error = [NSError errorWithDomain:@"com.zaneshannon.libhypem" code:1 userInfo:@{@"message": @"couldn't get a cookie from hypem.com"}];
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
			NSString *responseString = [[NSString alloc] initWithData:blockOperation.responseData encoding:NSUTF8StringEncoding];
			if (responseString) {
				NSError *error = nil;
				id object = [NSJSONSerialization
							 JSONObjectWithData:[responseString dataUsingEncoding:NSUTF8StringEncoding]
							 options:0
							 error:&error];
				if (error) {
					error = [NSError errorWithDomain:@"com.zaneshannon.libhypem" code:2 userInfo:@{@"message": @"hypem returned invalid JSON on auth"}];
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
						NSError *error = [NSError errorWithDomain:@"com.zaneshannon.libhypem" code:3 userInfo:@{@"message": @"invalid username or password"}];
						completion(nil, error);
					});
				}
			}
			else {
				dispatch_async(dispatch_get_main_queue(), ^{
					NSError *error = [NSError errorWithDomain:@"com.zaneshannon.libhypem" code:4 userInfo:@{@"message": @"could not parse response from hypem"}];
					completion(nil, error);
				});
			}
		}
		else {
			dispatch_async(dispatch_get_main_queue(), ^{
				NSError *error = [NSError errorWithDomain:@"com.zaneshannon.libhypem" code:5 userInfo:@{@"message": @"got no response from hypem"}];
				completion(nil, error);
			});
		}
	};
	[self.queue addOperation:operation];
}

+ (void) clearCookies {
	[[NSHTTPCookieStorage sharedHTTPCookieStorage] deleteCookie:[APIClient getCookie]];
}

#pragma mark - Playlists
- (void) getPlaylistOfType:(NSString*)type withArg:(NSString*)arg andPage:(NSUInteger)page withCompletion:(void (^)(NSArray *tracks, NSError *error))completion {
	// Setup completion handler
	__block NSArray *tracksWithKeys;
	__block NSArray *tracksWithoutKeys;
	void (^completionHandler)(NSArray *tracks, NSError *error) = ^void(NSArray *tracks, NSError *error) {
		
		if (error == nil) {
			if ([tracks[0] isKindOfClass:[Track class]]) {
				tracksWithoutKeys = tracks;
			}
			else {
				tracksWithKeys = tracks;
			}
			if (tracksWithoutKeys != nil && tracksWithKeys != nil) {
				dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
					NSMutableArray *responseTracks = [[NSMutableArray alloc] init];
					
					for (Track *track in tracksWithoutKeys) {
						for (NSDictionary *trackData in tracksWithKeys) {
							if ([[trackData valueForKey:@"id"] isEqualToString:[track.metadata valueForKey:@"mediaid"]]) {
								NSMutableDictionary *metadata = [track.metadata mutableCopy];
								[metadata setObject:[trackData valueForKey:@"key"] forKey:@"key"];
								track.metadata = metadata;
								[responseTracks addObject:track];
							}
						}
					}
					
					dispatch_async(dispatch_get_main_queue(), ^{
						completion(responseTracks, nil);
					});
				});
			}
		}
		else {
			completion(tracks, error);
		}
	};
	// JSON Request
	NSString *urlPath = [NSString stringWithFormat:kPlaylistAction, kBaseAPIAddress];
	urlPath = [urlPath stringByReplacingOccurrencesOfString:@":type" withString:type];
	urlPath = [urlPath stringByReplacingOccurrencesOfString:@":arg" withString:arg];
	urlPath = [urlPath stringByReplacingOccurrencesOfString:@":page" withString:[NSString stringWithFormat:@"%lu", (unsigned long)page]];
	
	NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:[NSURL URLWithString:urlPath] cachePolicy:NSURLRequestReloadIgnoringCacheData timeoutInterval:10];
	[request setHTTPShouldHandleCookies:YES];
	[request setHTTPMethod:@"GET"];
	[request setValue:@"text/json; charset=UTF-8" forHTTPHeaderField:@"Content-Type"];
	
	// Start the Operation
	Operation *operation = [[Operation alloc] init];
	operation.urlRequest = request;
	__block Operation *blockOperation = operation;
	operation.completionBlock = ^{
		if (blockOperation.responseData) {
			NSString *responseString = [[NSString alloc] initWithData:blockOperation.responseData encoding:NSUTF8StringEncoding];
			
			if (responseString) {
				NSError *error = nil;
				id object = [NSJSONSerialization
							 JSONObjectWithData:[responseString dataUsingEncoding:NSUTF8StringEncoding]
							 options:0
							 error:&error];
				if (error || ![object isKindOfClass:[NSDictionary class]]) {
					error = [NSError errorWithDomain:@"com.zaneshannon.libhypem" code:2 userInfo:@{@"message": @"hypem returned invalid JSON on auth"}];
					completionHandler(nil, error);
				}
				else {
					
					NSMutableArray *tracks = [[NSMutableArray alloc] init];
					
					int count = 0;
					for (NSString* key in object) {
						if ([[object objectForKey:key] isKindOfClass:[NSDictionary class]]) {
							count++;
						}
					}
					NSInteger offset = (page - 1) * count;
					
					for (NSString* key in object) {
						id value = [object objectForKey:key];
						NSInteger index = [key integerValue];
						if ([value isKindOfClass:[NSDictionary class]]) {
							NSMutableDictionary *mutableValue = [value mutableCopy];
							[mutableValue setObject:[NSNumber numberWithLong:(index + offset)] forKey:@"position"];
							NSDictionary *metadata = [mutableValue copy];
							Track *track = [Track trackFromMetadata:metadata];
							[tracks addObject:track];
						}
					}
					
					NSSortDescriptor *sortByName = [NSSortDescriptor sortDescriptorWithKey:@"position" ascending:YES];
					NSArray *sortDescriptors = [NSArray arrayWithObject:sortByName];
					NSArray *sortedTracks = [tracks sortedArrayUsingDescriptors:sortDescriptors];
					
					dispatch_async(dispatch_get_main_queue(), ^{
						completionHandler(sortedTracks, nil);
					});
				}
			}
			else {
				dispatch_async(dispatch_get_main_queue(), ^{
					NSError *error = [NSError errorWithDomain:@"com.zaneshannon.libhypem" code:3 userInfo:@{@"message": @"could not parse response from hypem"}];
					completionHandler(nil, error);
				});
			}
		}
		else {
			dispatch_async(dispatch_get_main_queue(), ^{
				NSError *error = [NSError errorWithDomain:@"com.zaneshannon.libhypem" code:4 userInfo:@{@"message": @"got no response from hypem"}];
				completionHandler(nil, error);
			});
		}
	};
	[self.queue addOperation:operation];
	
	// HTML Request
	NSString *HTMLurlPath = [NSString stringWithFormat:kPlaylistHTMLAction, kBaseWebAddress];
	HTMLurlPath = [HTMLurlPath stringByReplacingOccurrencesOfString:@":type" withString:type];
	if (arg.length == 0) {
		HTMLurlPath = [HTMLurlPath stringByReplacingOccurrencesOfString:@"/:arg" withString:arg];
	}
	else {
		HTMLurlPath = [HTMLurlPath stringByReplacingOccurrencesOfString:@":arg" withString:arg];
	}
	HTMLurlPath = [HTMLurlPath stringByReplacingOccurrencesOfString:@":page" withString:[NSString stringWithFormat:@"%lu", (unsigned long)page]];
	
	NSMutableURLRequest *HTMLrequest = [[NSMutableURLRequest alloc] initWithURL:[NSURL URLWithString:HTMLurlPath] cachePolicy:NSURLRequestReloadIgnoringCacheData timeoutInterval:10];
	[HTMLrequest setHTTPShouldHandleCookies:YES];
	[HTMLrequest setHTTPMethod:@"GET"];
	
	// Start the Operation
	Operation *HTMLoperation = [[Operation alloc] init];
	HTMLoperation.urlRequest = HTMLrequest;
	__block Operation *HTMLblockOperation = HTMLoperation;
	HTMLoperation.completionBlock = ^{
		if (HTMLblockOperation.responseData) {
			NSString *responseString = [[NSString alloc] initWithData:HTMLblockOperation.responseData encoding:NSUTF8StringEncoding];
			
			if (responseString) {
				NSString *trash=@"", *responseObject=@"";
				NSScanner *scanner = [NSScanner scannerWithString:responseString];
				[scanner scanUpToString:@"id=\"displayList-data\"" intoString:&trash];
				[scanner scanUpToString:@"{" intoString:&trash];
				[scanner scanUpToString:@"</script>" intoString:&responseObject];
				
				NSError *error = nil;
				id object = [NSJSONSerialization
							 JSONObjectWithData:[responseObject dataUsingEncoding:NSUTF8StringEncoding]
							 options:0
							 error:&error];
				if (error || ![object isKindOfClass:[NSDictionary class]]) {
					error = [NSError errorWithDomain:@"com.zaneshannon.libhypem" code:2 userInfo:@{@"message": @"hypem returned invalid JSON on auth"}];
					completionHandler(nil, error);
				}
				else {
					
					dispatch_async(dispatch_get_main_queue(), ^{
						completionHandler([object objectForKey:@"tracks"], nil);
					});
				}
			}
			else {
				dispatch_async(dispatch_get_main_queue(), ^{
					NSError *error = [NSError errorWithDomain:@"com.zaneshannon.libhypem" code:3 userInfo:@{@"message": @"could not parse response from hypem"}];
					completionHandler(nil, error);
				});
			}
		}
		else {
			dispatch_async(dispatch_get_main_queue(), ^{
				NSError *error = [NSError errorWithDomain:@"com.zaneshannon.libhypem" code:4 userInfo:@{@"message": @"got no response from hypem"}];
				completionHandler(nil, error);
			});
		}
	};
	[self.queue addOperation:HTMLoperation];
}

#pragma mark - Tracks
- (void) getDownloadURLForTrack:(Track*)track withCompletion:(void (^)(NSURL *url, NSError *error))completion {
	// JSON Request
	NSString *urlPath = [NSString stringWithFormat:kTrackDownloadAction, kBaseWebAddress];
	urlPath = [urlPath stringByReplacingOccurrencesOfString:@":mediaid" withString:[track.metadata valueForKey:@"mediaid"]];
	urlPath = [urlPath stringByReplacingOccurrencesOfString:@":key" withString:[track.metadata valueForKey:@"key"]];
	
	NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:[NSURL URLWithString:urlPath] cachePolicy:NSURLRequestReloadIgnoringCacheData timeoutInterval:10];
	[request setHTTPShouldHandleCookies:YES];
	[request setHTTPMethod:@"GET"];
	[request setValue:@"text/json; charset=UTF-8" forHTTPHeaderField:@"Content-Type"];
	
	// Start the Operation
	Operation *operation = [[Operation alloc] init];
	operation.urlRequest = request;
	__block Operation *blockOperation = operation;
	operation.completionBlock = ^{
		if (blockOperation.responseData) {
			NSString *responseString = [[NSString alloc] initWithData:blockOperation.responseData encoding:NSUTF8StringEncoding];
			if (responseString) {
				NSError *error = nil;
				id object = [NSJSONSerialization
							 JSONObjectWithData:[responseString dataUsingEncoding:NSUTF8StringEncoding]
							 options:0
							 error:&error];
				
				if (error || ![object isKindOfClass:[NSDictionary class]]) {
					error = [NSError errorWithDomain:@"com.zaneshannon.libhypem" code:2 userInfo:@{@"message": @"hypem returned invalid JSON on auth"}];
					completion(nil, error);
				}
				else {
					
					NSURL *downloadURL = [NSURL URLWithString:[object valueForKey:@"url"]];
					
					dispatch_async(dispatch_get_main_queue(), ^{
						completion(downloadURL, nil);
					});
				}
			}
			else {
				dispatch_async(dispatch_get_main_queue(), ^{
					NSError *error = [NSError errorWithDomain:@"com.zaneshannon.libhypem" code:3 userInfo:@{@"message": @"could not parse response from hypem"}];
					completion(nil, error);
				});
			}
		}
		else {
			dispatch_async(dispatch_get_main_queue(), ^{
				NSError *error = [NSError errorWithDomain:@"com.zaneshannon.libhypem" code:4 userInfo:@{@"message": @"got no response from hypem"}];
				completion(nil, error);
			});
		}
	};
	[self.queue addOperation:operation];
}

- (void) toggleFavoriteTrack:(Track*)track withCompletion:(void (^)(NSError *error))completion {
	NSString *urlPath = [NSString stringWithFormat:kLoginAction, kBaseAPIAddress];
	NSHTTPCookie *cookie = [APIClient getCookie];
	if (cookie == nil) {
		NSError *error = [NSError errorWithDomain:@"com.zaneshannon.libhypem" code:1 userInfo:@{@"message": @"couldn't get a cookie from hypem.com"}];
		completion(error);
		return;
	}
	// This is how we extract a session id from the cookie.. reverse engineered from hypem's JS
	NSString *authCookie = [cookie.value stringByReplacingPercentEscapesUsingEncoding:NSASCIIStringEncoding];
	NSArray *authCookieArray = [authCookie componentsSeparatedByString:@":"];
	NSString *session_id = authCookieArray[1];
	// This is the contstruction the auth checker expects
	NSString *bodyString = [NSString stringWithFormat:@"act=toggle_favorite&session=%@&type=item&val=%@", session_id, track.mediaid];
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
			NSString *responseString = [[NSString alloc] initWithData:blockOperation.responseData encoding:NSUTF8StringEncoding];
			if (responseString) {
				if ([responseString isEqualToString:@"1"] || [responseString isEqualToString:@"0"]) {
					completion(nil); // Success!
				}
			}
			else {
				dispatch_async(dispatch_get_main_queue(), ^{
					NSError *error = [NSError errorWithDomain:@"com.zaneshannon.libhypem" code:4 userInfo:@{@"message": @"could not parse response from hypem"}];
					completion(error);
				});
			}
		}
		else {
			dispatch_async(dispatch_get_main_queue(), ^{
				NSError *error = [NSError errorWithDomain:@"com.zaneshannon.libhypem" code:5 userInfo:@{@"message": @"got no response from hypem"}];
				completion(error);
			});
		}
	};
	[self.queue addOperation:operation];
}

#pragma mark - Users

- (void) getUserProfile:(User*)user withCompletion:(void (^)(NSDictionary *profile, NSError *error))completion {
	NSString *urlPath = [NSString stringWithFormat:kUserProfileAction, kBaseAPIAddress];
	urlPath = [urlPath stringByReplacingOccurrencesOfString:@":username" withString:user.username];
	
	NSLog(@"getUserProfile: %@", urlPath);
	
	NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:[NSURL URLWithString:urlPath] cachePolicy:NSURLRequestReloadIgnoringCacheData timeoutInterval:10];
	[request setHTTPShouldHandleCookies:YES];
	[request setHTTPMethod:@"GET"];
	[request setValue:@"text/json; charset=UTF-8" forHTTPHeaderField:@"Content-Type"];
	
	// Start the Operation
	Operation *operation = [[Operation alloc] init];
	operation.urlRequest = request;
	__block Operation *blockOperation = operation;
	operation.completionBlock = ^{
		if (blockOperation.responseData) {
			NSString *responseString = [[NSString alloc] initWithData:blockOperation.responseData encoding:NSUTF8StringEncoding];
			
			if (responseString) {
				NSError *error = nil;
				id object = [NSJSONSerialization
							 JSONObjectWithData:[responseString dataUsingEncoding:NSUTF8StringEncoding]
							 options:0
							 error:&error];
				if (error || ![object isKindOfClass:[NSDictionary class]]) {
					error = [NSError errorWithDomain:@"com.zaneshannon.libhypem" code:2 userInfo:@{@"message": @"hypem returned invalid JSON on auth"}];
					completion(nil, error);
				}
				else {
					dispatch_async(dispatch_get_main_queue(), ^{
						completion(object, nil);
					});
				}
			}
			else {
				dispatch_async(dispatch_get_main_queue(), ^{
					NSError *error = [NSError errorWithDomain:@"com.zaneshannon.libhypem" code:3 userInfo:@{@"message": @"could not parse response from hypem"}];
					completion(nil, error);
				});
			}
		}
		else {
			dispatch_async(dispatch_get_main_queue(), ^{
				NSError *error = [NSError errorWithDomain:@"com.zaneshannon.libhypem" code:4 userInfo:@{@"message": @"got no response from hypem"}];
				completion(nil, error);
			});
		}
	};
	[self.queue addOperation:operation];
}

- (void) getFavoriteBlogs:(User*)user withCompletion:(void (^)(NSArray *blogs, NSError *error))completion {
	// TODO: implement this! Issue #6
	NSError *error = [NSError errorWithDomain:@"not implemented" code:1 userInfo:nil];
	completion(nil, error);
}

- (void) getFriendsForUser:(User*)user withCompletion:(void (^)(NSArray *users, NSError *error))completion {
	// TODO: implement this! Issue #6
	NSError *error = [NSError errorWithDomain:@"not implemented" code:1 userInfo:nil];
	completion(nil, error);
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