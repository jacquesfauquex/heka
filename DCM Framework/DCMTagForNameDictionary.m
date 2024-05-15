#import "DCMTagForNameDictionary.h"
#import "DCM.h"

static DCMTagForNameDictionary *sharedTagForNameDictionary; 

@implementation DCMTagForNameDictionary

+(id)sharedTagForNameDictionary
{
	if (!sharedTagForNameDictionary)
	{
		NSBundle *bundle;
		if (DCMFramework_compile)
			bundle  = [NSBundle bundleForClass:NSClassFromString(@"DCMTagForNameDictionary")];
		else
			bundle = [NSBundle mainBundle];
			
		NSString *path = [bundle pathForResource:@"nameDictionary" ofType:@"plist"];
		if( path == nil)
		{
			
		}
		
		sharedTagForNameDictionary = (DCMTagForNameDictionary *)[[NSDictionary dictionaryWithContentsOfFile:path] retain];
	}
	return sharedTagForNameDictionary;
}

- (void) dealloc {
	[sharedTagForNameDictionary release];
	[super dealloc];
}


@end
