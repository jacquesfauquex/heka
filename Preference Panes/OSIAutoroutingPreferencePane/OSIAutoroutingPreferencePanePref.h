#import <PreferencePanes/PreferencePanes.h>

@interface OSIAutoroutingPreferencePanePref : NSPreferencePane <NSTableViewDelegate>
{
	IBOutlet NSWindow					*newRoute;
	IBOutlet NSTableView				*routesTable;
	
	IBOutlet NSTextField				*newName, *addressAndPort, *newFilter, *newDescription;
	IBOutlet NSPopUpButton				*serverPopup;
	
	IBOutlet NSPopUpButton				*previousPopup;
	IBOutlet NSButton					*previousModality;
	IBOutlet NSButton					*previousDescription;
	IBOutlet NSButton					*cfindTest;
	
	IBOutlet NSPopUpButton				*failurePopup;
	
	NSMutableArray						*routesArray;
	NSArray								*serversArray;
	int filterType;
    BOOL imagesOnly;
	
	IBOutlet NSWindow *mainWindow;
    
    
    BOOL deleteAfterTransference;
    
    //Schedule attributes
    
    int scheduleType;
    IBOutlet NSTextField* delayTime;
    IBOutlet NSDatePicker* fromTimePicker;
    IBOutlet NSDatePicker* toTimePicker;
    
    id _tlos;
}

@property int filterType;
@property BOOL imagesOnly;

- (void) mainViewDidLoad;
- (IBAction) endNewRoute:(id) sender;
- (IBAction) newRoute:(id) sender;
- (IBAction) syntaxHelpButtons:(id) sender;
- (void) deleteSelectedRow:(id)sender;
- (IBAction) selectServer:(id) sender;
- (IBAction) selectPrevious:(id) sender;

@property BOOL deleteAfterTransference;

@property int scheduleType;

@end
