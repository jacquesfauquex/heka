#import "NSButton+N2.h"
#import "NS(Attributed)String+Geometrics.h"
#import "N2Operators.h"
#import "NSString+N2.h"

@implementation NSButton (N2)

-(id)initWithOrigin:(NSPoint)origin title:(NSString*)title font:(NSFont*)font {
	NSSize size = [title sizeForWidth:MAXFLOAT height:MAXFLOAT font:font];
	self = [self initWithFrame:NSMakeRect(origin, size+NSMakeSize(4,1)*2)];
	[self setTitle:title];
	[self setFont:font];
	return self;
}

-(NSSize)optimalSizeForWidth:(CGFloat)width {
	NSSize size = [[self cell] cellSize];
	if (size.width > width) size.width = width;
	
	if ([self bezelStyle] == NSRecessedBezelStyle) {
        if ([[self cell] controlSize] == NSMiniControlSize) size.height -= 4;
    }
	
	return n2::ceil(size);
}

-(NSSize)optimalSize {
	return [self optimalSizeForWidth:CGFLOAT_MAX];
}

-(void)setTextColor:(NSColor*)color {
	NSMutableAttributedString* text = [[self attributedTitle] mutableCopy];
	NSRange range = text.range;
	
	[text addAttribute:NSForegroundColorAttributeName value:color range:range];
	[text fixAttributesInRange:range];
	[self setAttributedTitle:text];
	[text release];
	
	[self setNeedsDisplay:YES];
}

@end
