//
//  TrackTests.m
//  libhypem
//
//  Created by Zane Shannon on 10/28/14.
//
//

#import <XCTest/XCTest.h>
#import "XCTestCase+AsyncTesting.h"
#import "Playlist.h"
#import "HypeM.h"
#import "Track.h"

@interface TrackTests : XCTestCase

@property (strong, nonatomic) Track *track;

@end

@implementation TrackTests

- (void)setUp {
    [super setUp];
	Playlist *playlist = [Playlist popular:nil];
	XCTAssertNotNil(playlist);
	[playlist getNextPage:^(NSError *error) {
		XCTAssertNil(error);
		XCTAssertNotEqual(playlist.tracks.count, 0);
		self.track = playlist.tracks[0];
		[self notify:XCTAsyncTestCaseStatusSucceeded];
	}];
	[self waitForTimeout:10];
}

- (void)testAttributes {
	XCTAssertNotNil(self.track);
	XCTAssertNotNil(self.track.mediaid);
	XCTAssertNotNil(self.track.siteid);
	XCTAssertNotNil(self.track.posturl);
	XCTAssertNotNil(self.track.postid);
	XCTAssertNotNil(self.track.sitename);
	XCTAssertNotNil(self.track.dateposted);
	XCTAssertNotNil([self.track publicDownloadURL]);
}

- (void)testInternalDownloadURL {
	XCTAssertNotNil(self.track);
	[self.track internalDownloadURL:^(NSURL *url, NSError *error) {
		XCTAssertNil(error);
		XCTAssertNotNil(url);
		[self notify:XCTAsyncTestCaseStatusSucceeded];
	}];
	[self waitForTimeout:10];
}

- (void)testFavoriting {
	XCTAssertNotNil(self.track);
	[self.track favorite:^(NSError *error) {
		XCTAssertNil(error);
		[self notify:XCTAsyncTestCaseStatusSucceeded];
	}];
	[self waitForTimeout:10];
}

@end
