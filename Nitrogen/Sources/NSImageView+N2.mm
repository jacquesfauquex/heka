#import "NSImageView+N2.h"
#import "NSImage+N2.h"
#import "N2Operators.h"
#include <algorithm>

@implementation NSImageView (N2)

+(id)createWithImage:(NSImage*)image {
	id view = [[self alloc] initWithSize:[image size]];
	[view setImage:image];
	return [view autorelease];
}

-(NSSize)optimalSize {
	return n2::ceil([[self image] size]);
}

-(NSSize)optimalSizeForWidth:(CGFloat)width {
	NSSize imageSize = [[self image] size];
	if (width == CGFLOAT_MAX) width = imageSize.width;
	return n2::ceil(NSMakeSize(width, width/imageSize.width*imageSize.height));
}

@end
