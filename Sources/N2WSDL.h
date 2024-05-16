#import <Cocoa/Cocoa.h>


@interface N2WSDL : NSObject {
	NSMutableArray* _types;
	NSMutableArray* _messages;
	NSMutableArray* _operations;
	NSMutableArray* _portTypes;
	NSMutableArray* _bindings;
	NSMutableArray* _ports;
	NSMutableArray* _services;
}

-(id)initWithContentsOfURL:(NSURL*)url;

@end
