


#import <Foundation/Foundation.h>

/** \brief Wrapper for NSPoint */

@interface MyPoint : NSObject<NSCoding> {
	NSPoint pt;
}

@property(assign) NSPoint point;
@property(readonly) float x, y;

+ (MyPoint*)point:(NSPoint)a;
- (id)initWithPoint:(NSPoint)a;

- (void)setPoint:(NSPoint)a;
- (void)move:(float)x :(float)y;

- (BOOL)isEqualToPoint:(NSPoint)a;
- (BOOL)isNearToPoint:(NSPoint)a :(float)scale :(float)ratio;

@end
