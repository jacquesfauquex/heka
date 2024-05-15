#import "DarkBox.h"


@implementation DarkBox

- (void)drawRect:(NSRect)rect{
	NSColor *backgroundColor = [NSColor  colorWithCalibratedRed:0.7 green:0.7 blue:0.7 alpha:0.25];
	[backgroundColor setFill];	
	[NSBezierPath fillRect:rect];
	[super drawRect:rect];

}

@end
