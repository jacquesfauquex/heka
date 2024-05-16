#import <Cocoa/Cocoa.h>


@interface NSTextView (N2)

+(NSTextView*)labelWithText:(NSString*)string;
+(NSTextView*)labelWithText:(NSString*)string alignment:(NSTextAlignment)alignment;

-(NSSize)adaptToContent;
-(NSSize)adaptToContent:(CGFloat)maxWidth;

-(NSSize)optimalSizeForWidth:(CGFloat)width;
-(NSSize)optimalSize;

@end
