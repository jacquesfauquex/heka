#import <Cocoa/Cocoa.h>


@interface NSColor (N2)

-(BOOL)isEqualToColor:(NSColor*)color;
-(BOOL)isEqualToColor:(NSColor*)color alphaThreshold:(CGFloat)alphaThreshold;

@end
