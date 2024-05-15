#import <Cocoa/Cocoa.h>

@interface N2OpenGLViewWithSplitsWindow : NSWindow
{
	BOOL needsEnableUpdate;
}

@property BOOL needsEnableUpdate;

- (void) disableUpdatesUntilFlush;

@end
