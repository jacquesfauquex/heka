#import <Cocoa/Cocoa.h>

@class DCMTKRootQueryNode;

/** \brief Controller for performing query */
@interface QueryArrayController : NSObject
{
	DCMTKRootQueryNode *rootNode;
	NSMutableDictionary *filters;
	NSString *callingAET;
	NSString *calledAET;
	NSString *hostname;
	NSString *port;
	NSArray *queries;
	NSDictionary *distantServer;
	NSLock *queryLock;
	int retrieveMode;
}

- (id)initWithCallingAET:(NSString *) myAET distantServer: (NSDictionary*) ds;

- (id)rootNode;
- (NSArray *)queries;
- (NSMutableDictionary*) filters;
- (void)addFilter:(id)filter forDescription:(NSString *)description;
- (void)sortArray:(NSArray *)sortDesc;
- (void)performQuery;
- (NSDictionary *)parameters;
- (void)performQuery: (BOOL) showError;

@end
