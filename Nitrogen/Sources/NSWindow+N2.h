#import <Cocoa/Cocoa.h>


@interface NSWindow (N2)

-(NSSize)contentSizeForFrameSize:(NSSize)frameSize;
-(NSSize)frameSizeForContentSize:(NSSize)contentSize;

-(CGFloat)toolbarHeight;

-(void)safelySetMovable:(BOOL)flag;
//-(void)safelySetUsesLightBottomGradient:(BOOL)flag;

@end
