//
//  Track.h
//  libhypem
//
//  Created by Zane Shannon on 10/24/14.
//
//

#import <Foundation/Foundation.h>

@interface Track : NSObject

@property (strong, nonatomic) NSDictionary *metadata;

+ (Track*) trackFromMetadata:(NSDictionary*)metadata;

- (NSNumber*) position;

@end
