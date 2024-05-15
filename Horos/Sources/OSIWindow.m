#import "OSIWindow.h"

static BOOL dontConstrainWindow = NO;

@implementation OSIWindow

+ (void) setDontConstrainWindow: (BOOL) v
{
	dontConstrainWindow = v;
}

- (NSRect) constrainFrameRect:(NSRect)frameRect toScreen:(NSScreen *)screen
{
	if( dontConstrainWindow)
		return frameRect;
	
	return [super constrainFrameRect: frameRect toScreen: screen]; 
}

- (void) dealloc
{
    NSLog( @"OSIWindow dealloc");
    
    [NSObject cancelPreviousPerformRequestsWithTarget: self];
    
    [super dealloc];
}

@end
