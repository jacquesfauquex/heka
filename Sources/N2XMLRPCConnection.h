#import <Cocoa/Cocoa.h>
#import "N2Connection.h"

@protocol N2XMLRPCConnectionDelegate <NSObject>

@optional
-(NSString*)selectorStringForXMLRPCRequestMethodName:(NSString*)name;
-(BOOL)isSelectorAvailableToXMLRPC:(NSString*)selectorString;

@end

@interface N2XMLRPCConnection : N2Connection {
	NSObject<N2XMLRPCConnectionDelegate>* _delegate;
	BOOL _executed, _waitingToClose, _dontSpecifyStringType;
	NSTimer* _timeout;
    NSXMLDocument* _doc;
}

@property(retain) NSObject<N2XMLRPCConnectionDelegate>* delegate;
@property BOOL dontSpecifyStringType;

-(void)handleRequest:(CFHTTPMessageRef)request;
-(id)methodCall:(NSString*)methodName params:(NSArray*)params error:(NSError**)error; 
-(void)writeAndReleaseResponse:(CFHTTPMessageRef)response;

-(NSUInteger)N2XMLRPCOptions;

@end

