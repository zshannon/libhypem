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

@interface LoginTests : XCTestCase

@end

@implementation LoginTests

- (void)testLogin {
	NSString *username = kUSERNAME;
	NSString *password = kPASSWORD;
	HypeM *h = [HypeM sharedInstance];
	[h loginWithUsername:username password:password completion:^(bool success, NSHTTPCookie *cookie, NSError *error) {
		XCTAssertTrue(success);
		[self notify:XCTAsyncTestCaseStatusSucceeded];
	}];
	[self waitForTimeout:10];
}

@end
