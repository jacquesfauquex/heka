#import <PreferencePanes/PreferencePanes.h>

@interface OSIWebSharingPreferencePanePref : NSPreferencePane 
{
	IBOutlet NSArrayController *studiesArrayController, *userArrayController;
	
	NSString *TLSAuthenticationCertificate;
	IBOutlet NSButton *TLSChooseCertificateButton, *TLSCertificateButton;
	
	IBOutlet NSTextField* addressTextField;
	IBOutlet NSTextField* portTextField;
	
	IBOutlet NSPanel* usersPanel;
	
	IBOutlet NSWindow* mainWindow;
	
    IBOutlet NSTableView* usersTable;
    
    id _tlos;
}
@property (retain) NSString *TLSAuthenticationCertificate;

- (void) mainViewDidLoad;
- (IBAction) openKeyChainAccess:(id) sender;
- (IBAction) smartAlbumHelpButton: (id) sender;
- (IBAction) chooseTLSCertificate: (id) sender;
- (IBAction) viewTLSCertificate: (id) sender;
- (IBAction) copyMissingCustomizedFiles: (id) sender;
- (IBAction) editUsers: (id) sender;
- (IBAction) exitEditUsers: (id) sender;

@end
