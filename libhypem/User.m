//
//  User.m
//  libhypem
//
//  Created by Zane Shannon on 10/23/14.
//
//

#import "User.h"
#import "HypeM.h"
#import "APIClient.h"

@implementation User

+ (User*) userWithName:(NSString*)name {
	User *user = [[User alloc] init];
	user.name = name;
	return user;
}

- (NSString*) name {
	return nil;
}

- (NSString*) full_name {
	return nil;
}

- (NSString*) joined_at {
	return nil;
}

- (NSString*) location {
	return nil;
}

- (NSString*) twitter_username {
	return nil;
}

- (NSString*) image_url {
	return nil;
}

- (NSString*) followed_users_count {
	return nil;
}

- (NSString*) followed_items_count {
	return nil;
}

- (NSString*) followed_sites_count {
	return nil;
}

- (NSString*) followed_queries_count {
	return nil;
}

- (void) fetchProfile:(void (^)(NSError *error))completion {
	APIClient *client = [HypeM sharedInstance].client;
	[client getUserProfile:self withCompletion:completion];
}

- (void) fetchFavoriteBlogs:(void (^)(NSArray *blogs, NSError *error))completion {
	APIClient *client = [HypeM sharedInstance].client;
	[client getFavoriteBlogs:self withCompletion:completion];
}

- (void) fetchFriends:(void (^)(NSArray *users, NSError *error))completion {
	APIClient *client = [HypeM sharedInstance].client;
	[client getFriendsForUser:self withCompletion:completion];
}


@end
