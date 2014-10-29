//
//  Track.m
//  libhypem
//
//  Created by Zane Shannon on 10/24/14.
//
//

#import "Track.h"
#import "HypeM.h"
#import "APIClient.h"

@implementation Track

+ (Track*) trackFromMetadata:(NSDictionary*)metadata {
	Track *track = [[Track alloc] init];
	track.metadata = metadata;
	return track;
}

- (NSString*) mediaid {
	return [self.metadata valueForKey:@"mediaid"];
}

- (NSString*) siteid {
	return [[self.metadata valueForKey:@"siteid"] stringValue];
}

- (NSString*) posturl {
	return [self.metadata valueForKey:@"posturl"];
}

- (NSString*) postid {
	return [[self.metadata valueForKey:@"postid"] stringValue];
}

- (NSString*) sitename {
	return [self.metadata valueForKey:@"sitename"];
}

- (NSString*) dateposted {
	return [[self.metadata valueForKey:@"dateposted"] stringValue];
}

- (NSNumber*) position {
	if (self.metadata != nil) {
		return (NSNumber*) [self.metadata valueForKey:@"position"];
	}
	return nil;
}

- (NSURL*) publicDownloadURL {
	return [NSURL URLWithString:[NSString stringWithFormat:@"http://hypem.com/serve/public/%@", self.mediaid]];
}

- (void) internalDownloadURL:(void (^)(NSURL *url, NSError *error))completion {
	APIClient *client = [HypeM sharedInstance].client;
	[client getDownloadURLForTrack:self withCompletion:completion];
}

- (void) favorite:(void (^)(NSError *error))completion {
	// TODO: should implement this! Issue #5
	NSError *error = [NSError errorWithDomain:@"not implemented" code:1 userInfo:nil];
	completion(error);
}

@end
