//
//  APIClient.h
//  libhypem
//
//  Created by Zane Shannon on 10/23/14.
//
//

#import <Foundation/Foundation.h>
#import "User.h"

#pragma mark - Blocks
typedef void (^LoginCompletion) (bool success, NSHTTPCookie *cookie, NSError *error);

#pragma mark - APIClient
@interface APIClient : NSObject

#pragma mark - Authorization
- (void)loginWithUsername:(NSString *)username pass:(NSString *)password completion:(LoginCompletion)completion;
- (void)validateAndSetSessionWithCookie:(NSHTTPCookie *)cookie completion:(LoginCompletion)completion;

#pragma mark - Manage Requests
- (void)cancelAllRequests;

@end


#pragma mark - Operation
@interface Operation : NSOperation

// Properties
@property (nonatomic, retain) NSURLRequest *urlRequest;
@property (nonatomic, retain) NSData *bodyData;
@property (nonatomic, retain) NSData *responseData;
@property (nonatomic, retain) NSHTTPURLResponse *response;

// Set Path
-(void)setUrlPath:(NSString *)path data:(NSData *)data cookie:(NSHTTPCookie *)cookie completion:(void (^)(void))block;

// Web Request Builders
+(NSMutableURLRequest *)newGetRequestForURL:(NSURL *)url cookie:(NSHTTPCookie *)cookie;
+(NSMutableURLRequest *)newJSONRequestWithURL:(NSURL *)url bodyData:(NSData *)bodyData cookie:(NSHTTPCookie *)cookie;

@end