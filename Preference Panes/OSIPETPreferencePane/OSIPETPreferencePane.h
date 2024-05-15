#import <PreferencePanes/PreferencePanes.h>

@interface OSIPETPreferencePane : NSPreferencePane 
{
	IBOutlet NSPopUpButton					*CLUTBlendingMenu, *DefaultCLUTMenu, *OpacityTableMenu;
	
	IBOutlet NSMatrix						*CLUTMode, *WindowingModeMatrix;
	IBOutlet NSTextField					*minimumValueText;
    IBOutlet NSWindow						*mainWindow;
    
    id _tlos;
}

- (void) mainViewDidLoad;
- (IBAction) setPETCLUTfor3DMIP: (id) sender;
- (IBAction) setWindowingMode: (id) sender;
- (IBAction) setMinimumValue: (id) sender;
@end
