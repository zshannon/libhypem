//
//  Blog.h
//  libhypem
//
//  Created by Zane Shannon on 10/28/14.
//
//

#import <Foundation/Foundation.h>

@interface Blog : NSObject

@property (strong, nonatomic) NSString *id;
@property (strong, nonatomic) NSDictionary *metadata;

+ (Blog*) blogWithID:(NSString*)blog_id;

@end
