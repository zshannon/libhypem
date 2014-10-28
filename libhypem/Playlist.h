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

#import <Foundation/Foundation.h>

#pragma mark - Enums
typedef NS_ENUM(NSInteger, PopularArgs) {
	PlaylistThreeDay,
	PlaylistLastWeek,
	PlaylistNoRemix,
	PlaylistArtists,
	PlaylistTwitter
};

@interface Playlist : NSObject 

@property (strong, nonatomic) NSString *type;
@property (strong, nonatomic) NSString *arguments;
@property (strong, nonatomic) NSArray *tracks;

+ (Playlist*) popular:(NSString*)filter;
+ (Playlist*) latest:(NSString*)filter;
+ (Playlist*) friendsHistory:(NSString*)username;
+ (Playlist*) friendsFavorites:(NSString*)username;
+ (Playlist*) tagged:(NSString*)tag;
+ (Playlist*) taggedWithTags:(NSArray*)tags;
+ (Playlist*) blog:(NSString*)name;
+ (Playlist*) search:(NSString*)query;
+ (Playlist*) artist:(NSString*)name;
+ (Playlist*) feed:(NSString*)name;
+ (Playlist*) loved:(NSString*)username;
+ (Playlist*) obsessed:(NSString*)username;


- (void) getNextPage:(void (^)(NSError *error))completion;

@end
