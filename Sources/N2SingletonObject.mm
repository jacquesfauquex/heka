#import "N2SingletonObject.h"

@implementation N2SingletonObject

-(id)init {
	if (!_hasInited) {
		self = [super init];
		_hasInited = YES;
	}
	
	return self;
}

-(id)retain {
	return self;
}

-(oneway void)release {
}

-(id)autorelease {
	return self;
}

-(NSUInteger)retainCount {
	return UINT_MAX;
}

@end
