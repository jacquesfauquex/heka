#import <PreferencePanes/PreferencePanes.h>

#import "DICOMTLS.h"

@interface OSIListenerPreferencePanePref : NSPreferencePane 
{
	IBOutlet NSTextField *ipField;
	IBOutlet NSTextField *nameField;
	
	IBOutlet NSTextField* sharingNameField;	
	
	IBOutlet NSPopUpButton *preferredSyntaxPopUpButton;	
	
	IBOutlet NSWindow *TLSSettingsWindow;
	NSString *TLSAuthenticationCertificate;
	IBOutlet NSButton *TLSChooseCertificateButton, *TLSCertificateButton;
	NSArray *TLSSupportedCipherSuite;
	BOOL TLSUseDHParameterFileURL;
	NSURL *TLSDHParameterFileURL;
	
	TLSCertificateVerificationType	TLSCertificateVerification;
	
	BOOL TLSUseSameAETITLE;
	NSString *TLSStoreSCPAETITLE;
	IBOutlet NSButton *TLSStoreSCPAETITLEIsDefaultAETButton;
	BOOL TLSStoreSCPAETITLEIsDefaultAET;
	
	IBOutlet NSTextField *TLSAETitleTextField;
	IBOutlet NSTextField *TLSPortTextField;
	IBOutlet NSTextField *TLSPreferredSyntaxTextField;
	
    IBOutlet NSWindow *mainWindow;
    
    id _tlos;
}

@property (retain) NSString *TLSAuthenticationCertificate, *TLSStoreSCPAETITLE;
@property (retain) NSArray *TLSSupportedCipherSuite;
@property BOOL TLSUseDHParameterFileURL, TLSUseSameAETITLE, TLSStoreSCPAETITLEIsDefaultAET;
@property (retain) NSURL *TLSDHParameterFileURL;
@property TLSCertificateVerificationType TLSCertificateVerification;

- (void) mainViewDidLoad;

-(IBAction)editAddresses:(id)sender;
-(IBAction)editHostname:(id)sender;

#pragma mark TLS
- (IBAction)editTLS:(id)sender;
- (IBAction)cancel:(id)sender;
- (IBAction)ok:(id)sender;
- (IBAction)chooseTLSCertificate:(id)sender;
- (IBAction)viewTLSCertificate:(id)sender;
- (void)getTLSCertificate;
- (IBAction)useSameAETitleForTLSListener:(id)sender;
- (IBAction)activateDICOMTLSListenerAction:(id)sender;
- (void)updateTLSStoreSCPAETITLEIsDefaultAETButton;
- (IBAction)selectAllSuites:(id)sender;
- (IBAction)deselectAllSuites:(id)sender;

@end
