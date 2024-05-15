
#import <Cocoa/Cocoa.h>


@interface ColorView : NSView {
	NSColor *color;
}

- (void)setColor:(NSColor*)newColor;

@end
