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

+ (User*) userWithUsername:(NSString*)username {
	User *user = [[User alloc] init];
	user.username = username;
	return user;
}

- (NSString*) full_name {
	return [self.metadata valueForKey:@"fullname"];
}

- (NSString*) joined_at {
	return [self.metadata valueForKey:@"joined_ts"];
}

- (NSString*) location {
	return [self.metadata valueForKey:@"location"];
}

- (NSString*) twitter_username {
	return [self.metadata valueForKey:@"twitter_username"];
}

- (NSString*) image_url {
	return [self.metadata valueForKey:@"user_pic"];
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
	[client getUserProfile:self withCompletion:^(NSDictionary *profile, NSError *error) {
		if (error != nil) {
			self.metadata = profile;
		}
		if (completion != nil) completion(error);
	}];
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
