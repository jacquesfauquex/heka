#import <Cocoa/Cocoa.h>


@interface N2AdaptiveBox : NSBox {
	NSSize idealContentSize;
}

-(void)setContentView:(NSView*)view;
-(NSAnimation*)adaptContainersToIdealSize:(NSSize)size;
-(NSAnimation*)adaptContainersToIdealSize;

@end


@interface NSWindowController (N2AdaptiveBox)

-(NSAnimation*)synchronizeSizeWithContent;

@end
