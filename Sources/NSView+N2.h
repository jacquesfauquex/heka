#import <Cocoa/Cocoa.h>


@interface NSView (N2)

// Shortcut to [NSView initWithFrame:NSMakeRect(NSZeroPoint, size)]
-(id)initWithSize:(NSSize)size;
-(NSRect)sizeAdjust;
-(NSImage *) screenshotByCreatingPDF;

@end

@protocol OptimalSize

-(NSSize)optimalSize;
-(NSSize)optimalSizeForWidth:(CGFloat)width;

@end
