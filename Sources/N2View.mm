#import <N2View.h>
#import <N2Layout.h>
#import <N2Operators.h>

NSString* N2ViewBoundsSizeDidChangeNotification = @"N2ViewBoundsSizeDidChangeNotification";
NSString* N2ViewBoundsSizeDidChangeNotificationOldBoundsSize = @"oldBoundsSize";

@interface N2View (Dummy)

- (id)additionalSubviews;

@end

@implementation N2View
@synthesize controlSize = _controlSize, minSize = _minSize, maxSize = _maxSize, layout = _layout, foreColor = _foreColor, backColor = _backColor;


-(void)dealloc {
	[self setForeColor:NULL];
	[self setBackColor:NULL];
	[self setLayout:NULL];
	[super dealloc];
}

-(void)resizeSubviews {
	[self resizeSubviewsWithOldSize:[self bounds].size];
}

-(void)resizeSubviewsWithOldSize:(NSSize)oldBoundsSize {
	[_layout layOut];
	[[NSNotificationCenter defaultCenter] postNotification:[NSNotification notificationWithName:N2ViewBoundsSizeDidChangeNotification object:self userInfo:[NSDictionary dictionaryWithObject:[NSValue valueWithSize:oldBoundsSize] forKey:N2ViewBoundsSizeDidChangeNotificationOldBoundsSize]]];
}

-(void)formatSubview:(NSView*)view {
	if (view) {
		if (_foreColor && [view respondsToSelector:@selector(setTextColor:)])
			[view performSelector:@selector(setTextColor:) withObject:_foreColor];
		if (_backColor && [view respondsToSelector:@selector(setBackgroundColor:)])
			[view performSelector:@selector(setBackgroundColor:) withObject:_backColor];
		else if ([view respondsToSelector:@selector(setDrawsBackground:)])
			[(NSText*)view setDrawsBackground:NO];
		//if ([view respondsToSelector:@selector(setFont:)] && [view performSelector:@selector(font)])
		//	[view performSelector:@selector(setFont:) withObject:[NSFont fontWithName:[[view performSelector:@selector(font)] fontName] size:[NSFont systemFontSizeForControlSize:[self controlSize]]]];
	} else
		view = self;
	
	for (NSView* subview in [view subviews])
		if (![subview isKindOfClass:[N2View class]] || [(N2View*)subview layout] == NULL)
			[self formatSubview:subview];
	if ([view respondsToSelector:@selector(additionalSubviews)])
		for (NSView* subview in [view performSelector:@selector(additionalSubviews)])
			if (![subview isKindOfClass:[N2View class]] || [(N2View*)subview layout] == NULL)
				[self formatSubview:subview];
}

-(void)didAddSubview:(NSView*)view {
	[self formatSubview:view];
}

-(void)setForeColor:(NSColor*)color {
	[_foreColor release];
	_foreColor = [color retain];
	for (NSView* view in [self subviews])
		[self formatSubview:view];
}

/*-(void)drawRect:(NSRect)rect { // for debugging purposes we may need to identify the view's borders
	[super drawRect:rect];
	NSGraphicsContext* context = [NSGraphicsContext currentContext];
	[context saveGraphicsState];
	
	[[NSColor redColor] set];
	[[NSBezierPath bezierPathWithRect:[self bounds]] stroke];
	
	[context restoreGraphicsState];
}*/

-(NSSize)optimalSize {
	if (_layout)
		return n2::ceil([_layout optimalSize]);
	else return [self frame].size;	
}

-(NSSize)optimalSizeForWidth:(CGFloat)width {
	if (_layout)
		return n2::ceil([_layout optimalSizeForWidth:width]);
	else return [self frame].size;
}

@end

