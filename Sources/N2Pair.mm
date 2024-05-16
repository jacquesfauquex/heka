#import "N2Pair.h"

@implementation N2Pair
@synthesize first = _first, second = _second;

-(id)initWith:(id)first and:(id)second {
	self = [super init];
	
	_first = [first retain];
	_second = [second retain];
	
	return self;
}

-(void)dealloc {
	[_first release];
	[_second release];
	[super dealloc];
}

@end
