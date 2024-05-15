#import "SelectionView.h"


@implementation SelectionView

- (id)initWithFrame:(NSRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        [self acceptsFirstMouse:nil];
    }
    return self;
}

- (void) drawRect:(NSRect)aRect
{
	NSRect insideRect = NSMakeRect(aRect.origin.x+1,aRect.origin.y+1,aRect.size.width-2,aRect.size.height-2);
	NSBezierPath *outsidePath = [NSBezierPath bezierPathWithRect:aRect];
	NSBezierPath *insidePath = [NSBezierPath bezierPathWithRect:insideRect];
	
	[outsidePath setLineWidth:2.0];
		
	[[NSColor blackColor] set];
	[insidePath stroke];

	[[NSColor selectedTextBackgroundColor] set];
	[outsidePath stroke];
}

- (BOOL)mouse:(NSPoint)aPoint inRect:(NSRect)aRect;
{
	return NO;
}

- (BOOL)acceptsFirstResponder;
{
	return NO;
}

@end
