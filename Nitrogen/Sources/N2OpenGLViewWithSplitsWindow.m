#import <N2OpenGLViewWithSplitsWindow.h>


@implementation N2OpenGLViewWithSplitsWindow

@synthesize needsEnableUpdate;

-(void)disableUpdatesUntilFlush
{
    if(!needsEnableUpdate)
        NSDisableScreenUpdates();
    needsEnableUpdate = YES;
}

-(void)flushWindow
{
    [super flushWindow];
    if(needsEnableUpdate)
    {
        needsEnableUpdate = NO;
        NSEnableScreenUpdates();
    }
}

@end
