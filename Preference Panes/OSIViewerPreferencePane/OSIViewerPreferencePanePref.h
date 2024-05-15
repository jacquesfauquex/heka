#import <PreferencePanes/PreferencePanes.h>

@class AppController;

@interface OSIViewerPreferencePanePref : NSPreferencePane 
{
    IBOutlet NSWindow *mainWindow;
    
    id _tlos;
}

- (AppController*) appController;
- (void) mainViewDidLoad;

@end
