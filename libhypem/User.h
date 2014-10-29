//
//  User.h
//  libhypem
//
//  Created by Zane Shannon on 10/23/14.
//
//

#import <Foundation/Foundation.h>

@interface User : NSObject

@property (strong, nonatomic) NSString *name;
@property (strong, nonatomic) NSDictionary *metadata;

+ (User*) userWithName:(NSString*)name;

- (NSString*) name;
- (NSString*) full_name;
- (NSString*) joined_at;
- (NSString*) location;
- (NSString*) twitter_username;
- (NSString*) image_url;
- (NSString*) followed_users_count;
- (NSString*) followed_items_count;
- (NSString*) followed_sites_count;
- (NSString*) followed_queries_count;

- (void) fetchProfile:(void (^)(NSError *error))completion;
- (void) fetchFavoriteBlogs:(void (^)(NSArray *blogs, NSError *error))completion;
- (void) fetchFriends:(void (^)(NSArray *users, NSError *error))completion;

@end

