#import <N2DisclosureButtonCell.h>

@implementation N2DisclosureButtonCell
@synthesize attributes = _attributes;

-(id)init {
	self = [super init];
	[self setBezelStyle:NSDisclosureBezelStyle];
	[self setButtonType:NSOnOffButton];
	[self setState:NSOnState];
	[self setControlSize:NSSmallControlSize];
	[self sendActionOn:NSLeftMouseDownMask];
	
    _attributes = [[NSMutableDictionary alloc] initWithDictionary:@{
//						NSForegroundColorAttributeName: [NSColor whiteColor],
//						NSFontAttributeName: [NSFont labelFontOfSize:[NSFont smallSystemFontSize]],
                                                                    }];
	
	return self;
}

-(void)dealloc {
	[_attributes release];
	[super dealloc];
}

-(NSRect)titleRectForBounds:(NSRect)bounds {
//	NSSize size = [super cellSizeForBounds:bounds];
	NSSize textSize = [self textSize];
	return NSMakeRect(bounds.origin.x+bounds.size.width, bounds.origin.y, textSize.width, textSize.height);
}

-(NSSize)textSize {
	return [[self title] sizeWithAttributes:_attributes];
}

-(NSRect)drawTitle:(NSAttributedString*)title withFrame:(NSRect)frame inView:(NSView*)controlView {
	[[self title] drawInRect:frame withAttributes:_attributes];
	return frame;
}

-(id)copyWithZone:(NSZone *)zone {
    N2DisclosureButtonCell* copy = [super copyWithZone:zone];
    
    copy->_attributes = [self.attributes copyWithZone:zone];
    
    return copy;
}

@end
