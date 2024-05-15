#import <PreferencePanes/PreferencePanes.h>

@interface OSIHangingPreferencePanePref : NSPreferencePane 
{
	NSMutableDictionary *hangingProtocols;
	NSString *modalityForHangingProtocols;
	IBOutlet NSWindow *mainWindow;
    IBOutlet NSMenu *windowsTilingPopup;
    IBOutlet NSMenu *imageTilingPopup;
    IBOutlet NSMenu *WLWWPopup;
    IBOutlet NSArrayController *arrayController;
    
    IBOutlet NSWindow *addWLWWWindow;
    NSString *WLWWNewName;
    NSNumber *WLnew, *WWnew;
    NSMutableDictionary *currentWLWWProtocol;
    IBOutlet NSButton* newHangingProtocolButton;
    
    id _tlos;
}

@property (retain, nonatomic) NSString *modalityForHangingProtocols;
@property (retain) NSString *WLWWNewName;
@property (retain) NSNumber *WLnew, *WWnew;

- (void) mainViewDidLoad;
- (void) deleteSelectedRow:(id)sender;
- (IBAction) newHangingProtocol:(id)sender;


@end
