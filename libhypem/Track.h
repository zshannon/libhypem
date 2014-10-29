//
//  Track.h
//  libhypem
//
//  Created by Zane Shannon on 10/24/14.
//
//

#import <Foundation/Foundation.h>

@interface Track:  NSObject

@property (strong, nonatomic) NSDictionary *metadata;

+ (Track*) trackFromMetadata: (NSDictionary*)metadata;

- (NSString*) mediaid;
- (NSString*) siteid;
- (NSString*) posturl;
- (NSString*) postid;
- (NSString*) sitename;
- (NSString*) dateposted;
- (NSNumber*) position;
- (NSURL*) publicDownloadURL;
- (void) internalDownloadURL: (void (^)(NSURL *url, NSError *error))completion;
- (void) favorite:(void (^)(NSError *error))completion;

@end
