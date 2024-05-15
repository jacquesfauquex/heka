#import <AppKit/AppKit.h>
#import "ViewerController.h"

@interface ThumbnailsListPanel : NSWindowController
{	
	NSView                  *thumbnailsView;
    NSView                  *superView;
	long					screen;
	ViewerController		*viewer;
	BOOL					dontReenter;
}

@property (readonly) ViewerController *viewer;

+ (long) fixedWidth;
- (void) setThumbnailsView :(NSView*) tb viewer:(ViewerController*) v;
- (void) thumbnailsListWillClose :(NSView*) tb;
- (id)initForScreen: (long) s;
- (NSView*) thumbnailsView;
+ (void) checkScreenParameters;

@end
