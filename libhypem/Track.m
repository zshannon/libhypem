//
//  Track.m
//  libhypem
//
//  Created by Zane Shannon on 10/24/14.
//
//

#import "Track.h"

@implementation Track

+ (Track*) trackFromMetadata:(NSDictionary*)metadata {
	Track *track = [[Track alloc] init];
	track.metadata = metadata;
	return track;
}

- (NSNumber*) position {
	if (self.metadata != nil) {
		return (NSNumber*) [self.metadata valueForKey:@"position"];
	}
	return nil;
}

@end
