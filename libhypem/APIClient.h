//
//  APIClient.h
//  libhypem
//
//  Created by Zane Shannon on 10/23/14.
//
//

#import <Foundation/Foundation.h>

@class HypeM, Playlist, User, Track;

@interface APIClient : NSObject

#pragma mark - Authorization
- (void)loginWithUsername:(NSString *)username andPassword:(NSString *)password completion:(void (^)(User *user, NSError *error))completion;
+ (void) clearCookies;

#pragma mark - Playlists
- (void) getPlaylistOfType:(NSString*)type withArg:(NSString*)arg andPage:(NSUInteger)page withCompletion:(void (^)(NSArray *tracks, NSError *error))completion;

#pragma mark - Tracks
- (void) getDownloadURLForTrack:(Track*)track withCompletion:(void (^)(NSURL *url, NSError *error))completion;
- (void) toggleFavoriteTrack:(Track*)track withCompletion:(void (^)(NSError *error))completion;

#pragma mark - Users
- (void) getUserProfile:(User*)user withCompletion:(void (^)(NSError *error))completion;
- (void) getFavoriteBlogs:(User*)user withCompletion:(void (^)(NSArray *blogs, NSError *error))completion;
- (void) getFriendsForUser:(User*)user withCompletion:(void (^)(NSArray *users, NSError *error))completion;

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
