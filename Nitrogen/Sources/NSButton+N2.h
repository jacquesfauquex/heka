#import <Cocoa/Cocoa.h>


@interface NSButton (N2)

-(id)initWithOrigin:(NSPoint)origin title:(NSString*)title font:(NSFont*)font;

-(NSSize)optimalSizeForWidth:(CGFloat)width;
-(NSSize)optimalSize;

@end
