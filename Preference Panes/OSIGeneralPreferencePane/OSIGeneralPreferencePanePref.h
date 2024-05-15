#import <PreferencePanes/PreferencePanes.h>

@interface OSIGeneralPreferencePanePref : NSPreferencePane 
{
	IBOutlet NSWindow *compressionSettingsWindow;
	NSArray *compressionSettingsCopy, *compressionSettingsLowResCopy;
	IBOutlet NSWindow *mainWindow;
    IBOutlet NSButton *CheckUpdatesOnOff;
    NSMutableArray *languages;
    
    id _tlos;
}

@property (retain) NSMutableArray *languages;

- (IBAction) editCompressionSettings:(id) sender;
- (IBAction) endEditCompressionSettings:(id) sender;
- (IBAction) resetPreferences: (id) sender;
+ (void) applyLanguagesIfNeeded;
@end
