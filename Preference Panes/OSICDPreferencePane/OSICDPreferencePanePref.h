#import <PreferencePanes/PreferencePanes.h>

@interface OSICDPreferencePanePref : NSPreferencePane 
{
    IBOutlet NSWindow *mainWindow;
    
    id _tlos;
}

- (IBAction)chooseSupplementaryBurnPath:(id)sender;

@end
