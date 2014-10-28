// libhypem NSObject+libhypem.h
//
// Copyright © 2014, Zane Shannon
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
//	The above copyright notice and this permission notice shall be included in
//	all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS," WITHOUT WARRANTY OF ANY KIND, EITHER
// EXPRESSED OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
// MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NON-INFRINGEMENT. IN NO
// EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES
// OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE,
// ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER
// DEALINGS IN THE SOFTWARE.
//
//------------------------------------------------------------------------------

#import "Playlist.h"
#import "HypeM.h"
#import "APIClient.h"

@interface Playlist()

@property NSUInteger page;

@end

@implementation Playlist

+ (Playlist*) popular:(NSString*)filter {
	Playlist *playlist = [[Playlist alloc] init];
	NSArray *knownArgs = @[@"3day", @"lastweek", @"noremix", @"artists", @"twitter"];
	if (filter == nil) filter = knownArgs[0];
	if (![knownArgs containsObject:filter]) {
		[NSException raise:@"Invalid Popular Filter value" format:@"filter %@ is invalid", filter];
	}
	playlist.type = @"popular";
	playlist.arguments = filter;
	return playlist;
}

+ (Playlist*) latest:(NSString*)filter {
	Playlist *playlist = [[Playlist alloc] init];
	NSArray *knownArgs = @[@"all", @"noremix", @"remix", @"fresh"];
	if (filter == nil) filter = knownArgs[0];
	if (![knownArgs containsObject:filter]) {
		[NSException raise:@"Invalid Latest Filter value" format:@"filter %@ is invalid", filter];
	}
	playlist.type = @"latest";
	playlist.arguments = @"";
	return playlist;
}

+ (Playlist*) friendsHistory:(NSString*)username {
	Playlist *playlist = [[Playlist alloc] init];
	playlist.type = @"people_history";
	playlist.arguments = username;
	return playlist;
}

+ (Playlist*) friendsFavorites:(NSString*)username {
	Playlist *playlist = [[Playlist alloc] init];
	playlist.type = @"people";
	playlist.arguments = username;
	return playlist;
}

+ (Playlist*) tagged:(NSString*)tag {
	return [Playlist taggedWithTags:@[tag]];
}

+ (Playlist*) taggedWithTags:(NSArray*)tags {
	Playlist *playlist = [[Playlist alloc] init];
	playlist.type = @"tags";
	playlist.arguments = [tags componentsJoinedByString:@","];
	return playlist;
}

+ (Playlist*) blog:(NSString*)name {
	Playlist *playlist = [[Playlist alloc] init];
	playlist.type = @"blog";
	playlist.arguments = name;
	return playlist;
}

+ (Playlist*) search:(NSString*)query {
	Playlist *playlist = [[Playlist alloc] init];
	playlist.type = @"search";
	playlist.arguments = query;
	return playlist;
}

+ (Playlist*) artist:(NSString*)name {
	Playlist *playlist = [[Playlist alloc] init];
	playlist.type = @"artist";
	playlist.arguments = name;
	return playlist;
}

+ (Playlist*) feed:(NSString*)name {
	Playlist *playlist = [[Playlist alloc] init];
	playlist.type = @"feed";
	playlist.arguments = name;
	return playlist;
}

+ (Playlist*) loved:(NSString*)username {
	Playlist *playlist = [[Playlist alloc] init];
	playlist.type = @"loved";
	playlist.arguments = username;
	return playlist;
}

+ (Playlist*) obsessed:(NSString*)username {
	Playlist *playlist = [[Playlist alloc] init];
	playlist.type = @"obsessed";
	playlist.arguments = username;
	return playlist;
}

- (void) getNextPage:(void (^)(NSError *error))completion {
	if (self.page <= 0) self.page = 0;
	self.page++;
	__block Playlist *wself = self;
	APIClient *client = [HypeM sharedInstance].client;
	[client getPlaylistOfType:self.type withArg:self.arguments andPage:self.page withCompletion:^(NSArray *tracks, NSError *error) {
		if (error == nil) {
			NSMutableArray *mergedTracks = [[NSMutableArray alloc] init];
			[mergedTracks addObjectsFromArray:wself.tracks];
			[mergedTracks addObjectsFromArray:tracks];
			wself.tracks = [mergedTracks copy];
		}
		completion(error);
	}];
}

@end
