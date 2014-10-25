// libhypemTests libhypemTests.m
//
// Copyright © 2014, Zane Shannon
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the “Software”), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
//	The above copyright notice and this permission notice shall be included in
//	all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED “AS IS,” WITHOUT WARRANTY OF ANY KIND, EITHER
// EXPRESSED OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
// MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NON-INFRINGEMENT. IN NO
// EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES
// OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE,
// ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER
// DEALINGS IN THE SOFTWARE.
//
//------------------------------------------------------------------------------

#import <XCTest/XCTest.h>
#import "XCTestCase+AsyncTesting.h"
#import "Playlist.h"
#import "HypeM.h"
#import "Track.h"


@interface PlaylistTests : XCTestCase

@end

@implementation PlaylistTests

- (void)testplaylist {
	Playlist *playlist = [Playlist popular];
	XCTAssertNotNil(playlist);
	[playlist getNextPage:^(NSError *error) {
		XCTAssertNil(error);
		XCTAssertNotEqual(playlist.tracks.count, 0);
		NSInteger count = playlist.tracks.count;
		[playlist getNextPage:^(NSError *error) {
			XCTAssertNil(error);
			XCTAssertNotEqual(playlist.tracks.count, count);
			XCTAssertNotEqual(playlist.tracks[0], playlist.tracks[count - 1]);
			int idx = 0;
			for (id object in playlist.tracks) {
				XCTAssertTrue([object isKindOfClass:[Track class]]);
				Track *track = (Track*) object;
				XCTAssertEqual(idx, [track.position intValue]);
				idx++;
			}
			[self notify:XCTAsyncTestCaseStatusSucceeded];
		}];
	}];
	[self waitForTimeout:10];
}

- (void)testLatest {
	Playlist *playlist = [Playlist latest];
	XCTAssertNotNil(playlist);
	[playlist getNextPage:^(NSError *error) {
		XCTAssertNil(error);
		XCTAssertNotEqual(playlist.tracks.count, 0);
		NSInteger count = playlist.tracks.count;
		[playlist getNextPage:^(NSError *error) {
			XCTAssertNil(error);
			XCTAssertNotEqual(playlist.tracks.count, count);
			XCTAssertNotEqual(playlist.tracks[0], playlist.tracks[count - 1]);
			int idx = 0;
			for (id object in playlist.tracks) {
				XCTAssertTrue([object isKindOfClass:[Track class]]);
				Track *track = (Track*) object;
				XCTAssertEqual(idx, [track.position intValue]);
				idx++;
			}
			[self notify:XCTAsyncTestCaseStatusSucceeded];
		}];
	}];
	[self waitForTimeout:10];
}


@end
