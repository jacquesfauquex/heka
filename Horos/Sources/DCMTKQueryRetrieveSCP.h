#import <Cocoa/Cocoa.h>

/** \brief  DICOM Q/R SCP 
*
* DCMTKQueryRetrieveSCP is the Query/ Retrieve Server and listener
* based on DCMTK 
*/

@interface DCMTKQueryRetrieveSCP : NSObject {
	int _port;
	NSString *_aeTitle;
	NSDictionary *_params;
	BOOL _abort;
	BOOL running;
}

+ (BOOL) storeSCP;
- (id)initWithPort:(int)port aeTitle:(NSString *)aeTitle  extraParamaters:(NSDictionary *)params;
- (void)run;
- (void)abort;
- (int) port;
- (NSString*) aeTitle;
- (BOOL) running;
@end
