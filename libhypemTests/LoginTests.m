//
//  LoginTests.m
//  libhypem
//
//  Created by Zane Shannon on 10/23/14.
//
//

#import <Cocoa/Cocoa.h>
#import <XCTest/XCTest.h>
#import "XCTestCase+AsyncTesting.h"
#import "TestingContstants.h"
#import "HypeM.h"
#import "APIClient.h"

@interface LoginTests : XCTestCase

@end

@implementation LoginTests

- (void)testCookie {
	XCTAssertNotNil([APIClient getCookie]);
}

- (void)testLogin {
	NSString *username = kUSERNAME;
	NSString *password = kPASSWORD;
	HypeM *h = [HypeM sharedInstance];
	[h startSession];
	[h loginWithUsername:username andPassword:password completion:^(bool success, NSHTTPCookie *cookie, NSError *error) {
		XCTAssertTrue(success);
		[self notify:XCTAsyncTestCaseStatusSucceeded];
	}];
	[self waitForTimeout:10];
}

@end
