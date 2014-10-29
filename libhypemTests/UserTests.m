//
//  UserTests.m
//  libhypem
//
//  Created by Zane Shannon on 10/28/14.
//
//

#import <XCTest/XCTest.h>
#import "XCTestCase+AsyncTesting.h"
#import "HypeM.h"
#import "User.h"

@interface UserTests : XCTestCase

@property (strong, nonatomic) User *user;

@end

@implementation UserTests

- (void)setUp {
    [super setUp];
	self.user = [User userWithUsername:@"teddyjones"];
	XCTAssertNotNil(self.user);
}

- (void)testAttributes {
	XCTAssertNotNil(self.user.username);
	[self.user fetchProfile:^(NSError *error) {
		NSLog(@"user.metadata: %@", self.user.metadata);
		XCTAssertNil(error);
		XCTAssertNotNil(self.user);
		XCTAssertNotNil(self.user.username);
		XCTAssertEqualObjects(self.user.full_name, [self.user.metadata valueForKey:@"fullname"]);
		XCTAssertEqualObjects(self.user.joined_at, [self.user.metadata valueForKey:@"joined_ts"]);
		XCTAssertEqualObjects(self.user.location, [self.user.metadata valueForKey:@"location"]);
		XCTAssertEqualObjects(self.user.twitter_username, [self.user.metadata valueForKey:@"twitter_username"]);
		XCTAssertEqualObjects(self.user.image_url, [self.user.metadata valueForKey:@"user_pic"]);
//		XCTAssertNotNil(self.user.followed_users_count);
//		XCTAssertNotNil(self.user.followed_items_count);
//		XCTAssertNotNil(self.user.followed_sites_count);
//		XCTAssertNotNil(self.user.followed_queries_count);
		[self notify:XCTAsyncTestCaseStatusSucceeded];
	}];
	[self waitForTimeout:10];
}

- (void) testFetchFavoriteBlogs {
	[self.user fetchFavoriteBlogs:^(NSArray *blogs, NSError *error) {
		XCTAssertNil(error);
		// can't do more here because blogs might be empty legitimately
		[self notify:XCTAsyncTestCaseStatusSucceeded];
	}];
	[self waitForTimeout:10];
}

- (void) testFetchFriends {
	[self.user fetchFriends:^(NSArray *users, NSError *error) {
		XCTAssertNil(error);
		// can't do more here because users might be empty legitimately
		[self notify:XCTAsyncTestCaseStatusSucceeded];
	}];
	[self waitForTimeout:10];
}

@end
