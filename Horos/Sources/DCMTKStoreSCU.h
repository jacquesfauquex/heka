

#import <Cocoa/Cocoa.h>

#import "DICOMTLS.h"
#import "DDKeychain.h"

int runStoreSCU(const char *myAET, const char*peerAET, const char*hostname, int port, NSDictionary *extraParameters);

/** \brief  DICOM Send 
*
* DCMTKStoreSCU performs the DICOM send
* based on DCMTK 
*/
@interface DCMTKStoreSCU : NSObject {
	BOOL _threadStatus;
	
//conf
   NSString *_callingAET;
	NSString *_calledAET;
	int _port;
	NSString *_hostname;
	NSDictionary *_extraParameters;
	int _transferSyntax;
	float _compression;

//filePath array
	NSArray *_filesToSend;
	int _numberOfFiles;
	int _numberSent;
	int _numberErrors;
	
//TLS settings
	BOOL _secureConnection;
	BOOL _doAuthenticate;
	int  _keyFileFormat;
	NSArray *_cipherSuites;
	const char *_readSeedFile;
	const char *_writeSeedFile;
	TLSCertificateVerificationType certVerification;
	const char *_dhparam;	
}
+ (int) sendSyntaxForListenerSyntax: (int) listenerSyntax;
- (id) initWithCallingAET:(NSString *)myAET  
			calledAET:(NSString *)theirAET  
			hostname:(NSString *)hostname 
			port:(int)port 
			filesToSend:(NSArray *)filesToSend
			transferSyntax:(int)transferSyntax
			compression: (float)compression
			extraParameters:(NSDictionary *)extraParameters;
			
- (void)run:(NSOperation*) operation;
@end



