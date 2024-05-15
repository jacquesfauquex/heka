#import <PreferencePanes/PreferencePanes.h>

@interface AYDicomPrintPref : NSPreferencePane 
{
	NSArray *m_PrinterDefaults;
	IBOutlet NSArrayController *m_PrinterController;
	IBOutlet NSWindow *mainWindow;
    
    id _tlos;
}

- (IBAction) addPrinter: (id) sender;
- (IBAction) setDefaultPrinter: (id) sender;

- (IBAction) loadList: (id) sender;
- (IBAction) saveList: (id) sender;

@end
