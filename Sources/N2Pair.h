#import <Cocoa/Cocoa.h>

@interface N2Pair : NSObject {
	id _first, _second;
}

@property(retain) id first, second;

-(id)initWith:(id)first and:(id)second;

@end
