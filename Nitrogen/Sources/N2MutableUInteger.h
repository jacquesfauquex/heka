#import <Cocoa/Cocoa.h>


@interface N2MutableUInteger : NSObject {
	NSUInteger _value;
}

+(id)mutableUIntegerWithUInteger:(NSUInteger)value;

@property NSUInteger unsignedIntegerValue;

-(id)initWithUInteger:(NSUInteger)value;

-(void)increment;
-(void)decrement;

@end
