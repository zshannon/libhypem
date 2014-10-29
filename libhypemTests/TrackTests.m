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

@property (strong, nonatomic) Playlist *playlist;

@end

@implementation TrackTests

- (void)setUp {
    [super setUp];
	self.playlist = [Playlist popular:nil];
	XCTAssertNotNil(self.playlist);
	[self.playlist getNextPage:^(NSError *error) {
		XCTAssertNil(error);
		XCTAssertNotEqual(self.playlist.tracks.count, 0);
		[self notify:XCTAsyncTestCaseStatusSucceeded];
	}];
	[self waitForTimeout:10];
}

- (void)testDownloadURL {
	Track *track = self.playlist.tracks[0];
	XCTAssertNotNil(track);
	[track downloadURL:^(NSURL *url, NSError *error) {
		XCTAssertNil(error);
		XCTAssertNotNil(url);
		[self notify:XCTAsyncTestCaseStatusSucceeded];
	}];
	[self waitForTimeout:10];
}

@end
