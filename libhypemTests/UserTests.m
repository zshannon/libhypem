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
	self.user = [User userWithName:@"teddyjones"];
	XCTAssertNotNil(self.user);
}

- (void)testAttributes {
	[self.user fetchProfile:^(NSError *error) {
		XCTAssertNil(error);
		XCTAssertNotNil(self.user);
		XCTAssertNotNil(self.user.name);
		XCTAssertNotNil(self.user.full_name);
		XCTAssertNotNil(self.user.joined_at);
		XCTAssertNotNil(self.user.location);
		XCTAssertNotNil(self.user.twitter_username);
		XCTAssertNotNil(self.user.image_url);
		XCTAssertNotNil(self.user.followed_users_count);
		XCTAssertNotNil(self.user.followed_items_count);
		XCTAssertNotNil(self.user.followed_sites_count);
		XCTAssertNotNil(self.user.followed_queries_count);
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
