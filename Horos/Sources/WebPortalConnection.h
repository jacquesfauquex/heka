
#import <Cocoa/Cocoa.h>
#import "HTTPConnection.h"
#import "WebPortalUser.h"

@class WebPortal, WebPortalServer, WebPortalSession, WebPortalResponse, DicomDatabase;

@interface WebPortalConnection : HTTPConnection
{
	NSLock *sendLock, *running;
	WebPortalUser* user;
	WebPortalSession* session;
	
//    NSString* requestedPath;
	NSString* GETParams;
	NSDictionary* parameters; // GET and POST params
	
	WebPortalResponse* response;
	
	// POST / PUT support
	int dataStartIndex;
	NSMutableArray* multipartData;
	BOOL postHeaderOK;
	NSData *postBoundary;
	NSString *POSTfilename;
    
    DicomDatabase* _independentDicomDatabase;
    NSThread* _independentDicomDatabaseThread;
}

-(CFHTTPMessageRef)request;

@property(retain,readonly) WebPortalResponse* response;
@property(retain, nonatomic) WebPortalSession* session;
@property(retain) WebPortalUser* user;
@property(retain) NSDictionary* parameters;
@property(retain) NSString* GETParams;
@property(retain,readonly) DicomDatabase* independentDicomDatabase;
@property(strong) NSString *requestedPath;

@property(assign,readonly) WebPortalServer* server;
@property(assign,readonly) WebPortal* portal;
@property(assign,readonly) AsyncSocket* asyncSocket;

+(NSString*)FormatParams:(NSDictionary*)dict;
+(NSDictionary*)ExtractParams:(NSString*)paramsString;

-(BOOL)requestIsIPhone;
-(BOOL)requestIsIPad;
-(BOOL)requestIsIPod;
-(BOOL)requestIsIOS;
-(BOOL)requestIsMacOS;

-(NSString*)portalURL;
-(NSString*)dicomCStorePortString;
- (void) resetPOST;
- (void) fillSessionAndUserVariables;

@end

