
#import "DCMCalendarScript.h"

@implementation DCMCalendarScript

- (id)initWithCalendar:(NSString *)calendar{
	if (self = [super init]) {
		NSString *rootScript = [[[NSString alloc] initWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"iCal script" ofType:@"applescript"] usedEncoding:NULL error:NULL] autorelease];
		NSString *script = [NSString stringWithFormat:@"set the source_calendar to \"%@\"\n%@", calendar, rootScript];
		compiledScript = [[NSAppleScript alloc] initWithSource:script];
		
		
		//Important:  You should access NSAppleScript only from the main thread.
		[compiledScript performSelectorOnMainThread:@selector(compileAndReturnError:) withObject:nil waitUntilDone: YES];
//		[compiledScript compileAndReturnError:nil];
	}
	return self;
}

- (void)dealloc{
	[compiledScript  release];
	[super dealloc];
}

- (void) routingDestination: (NSMutableArray*) routingDestination
{
	NSAppleEventDescriptor *description  = [compiledScript executeAndReturnError:nil];
	NSString *route = [description stringValue];
	if (route && ![route isEqualToString: @""]) {
		NSArray *routes = [route componentsSeparatedByString:@"/"];
		NSString *nextRoute;
		for (nextRoute in routes) {
			NSMutableArray *routeParams = [NSMutableArray arrayWithArray:[nextRoute componentsSeparatedByString:@":"]];
			[routingDestination addObject:routeParams];
		}
	}
}

- (NSMutableArray *)routingDestination
{
	NSMutableArray *routingDestination = [NSMutableArray array];
	
	//Important:  You should access NSAppleScript only from the main thread.
	[self performSelectorOnMainThread:@selector(routingDestination:) withObject:routingDestination waitUntilDone: YES];
	
	if( [routingDestination count] > 0) return routingDestination;
	else return nil;
}

@end
