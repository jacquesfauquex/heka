#import "ThumbnailsListNSWindow.h"
#import "ThumbnailsListPanel.h"
#import "ViewerController.h"
#import "N2Debug.h"
#import "AppController.h"

@implementation ThumbnailsListNSWindow

- (BOOL) canBecomeMainWindow
{
	return NO;
}

- (BOOL) canBecomeKeyWindow
{
	return NO;
}

- (void) orderOut:(id)sender
{
    if( [[NSUserDefaults standardUserDefaults] boolForKey: @"SeriesListVisible"] == NO)
    {
        [super orderOut:sender];
        return;
    }
    
    if( [[NSUserDefaults standardUserDefaults] boolForKey: @"UseFloatingThumbnailsList"])
    {
        NSDisableScreenUpdates();
        
        ViewerController *v = [ViewerController frontMostDisplayed2DViewerForScreen: self.screen];
        if( v)
        {
            [self.windowController setThumbnailsView: v.previewMatrixScrollView viewer: v];
            
            if( v.window.windowNumber > 0)
                [self orderWindow: NSWindowBelow relativeTo: v.window.windowNumber];
        }
        else
        {
            [super orderOut:sender];
            [self.windowController setThumbnailsView: nil viewer: nil];
        }
        
        NSEnableScreenUpdates();
    }
    else
        [super orderOut:sender];
}

-(NSTimeInterval)animationResizeTime:(NSRect)newFrame {
	return 0;
}

-(NSRect)constrainFrameRect:(NSRect)frameRect toScreen:(NSScreen*)screen {
	return frameRect; // not movable, and OsiriX knows where to place toolbars ;)
}

@end
