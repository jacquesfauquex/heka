#import <Cocoa/Cocoa.h>
#import "N2OpenGLViewWithSplitsWindow.h"

@interface OSIWindow : N2OpenGLViewWithSplitsWindow
{
}

+ (void) setDontConstrainWindow: (BOOL) v;

@end
