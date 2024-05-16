#import <Cocoa/Cocoa.h>

@interface N2SingletonObject : NSObject {
	@protected
	BOOL _hasInited;
}

@end
