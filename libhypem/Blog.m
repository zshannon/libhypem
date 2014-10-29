//
//  Blog.m
//  libhypem
//
//  Created by Zane Shannon on 10/28/14.
//
//

#import "Blog.h"

@implementation Blog

+ (Blog*) blogWithID:(NSString*)blog_id {
	Blog *blog = [[Blog alloc] init];
	blog.id = blog_id;
	return blog;
}

@end
