

#import <Cocoa/Cocoa.h>

#import "WebKit/WebKit.h"

/** \brief  Window Controller for Splash Window */
@interface SplashScreen : NSWindowController <NSWindowDelegate>
{
	IBOutlet	NSButton *version;
	NSTimer		*timerIn, *timerOut;
	IBOutlet	id view;
	int         versionType;
    
    IBOutlet    WebView *aboutWebView;
}

- (void) affiche;
- (IBAction) opendicomwww:(id) sender;
@end
