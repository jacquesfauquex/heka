#import "NSUserDefaultsController+OsiriX.h"
#import "NSUserDefaultsController+N2.h"
#import "NSUserDefaults+OsiriX.h"


@implementation NSUserDefaultsController (OsiriX)
@end

@implementation NSUserDefaultsController (Deprecated)

NSString* const OsirixWebServerUsesWeasisDefaultsKey = OsirixWebPortalUsesWeasisDefaultsKey;
NSString* const OsirixWadoServerActiveDefaultsKey = OsirixWadoServiceEnabledDefaultsKey;
NSString* const OsirixWebServerPrefersFlashDefaultsKey = OsirixWebPortalPrefersFlashDefaultsKey;
NSString* const OsirixWebServerPrefersCustomWebPagesKey = OsirixWebPortalPrefersCustomWebPagesKey;


+(BOOL)WebServerUsesWeasis {
	return NSUserDefaults.webPortalUsesWeasis;
}

+(BOOL)WadoServerActive {
	return NSUserDefaults.wadoServiceEnabled;
}

+(BOOL)WebServerPrefersFlash {
	return NSUserDefaults.webPortalPrefersFlash;
}

+(BOOL)WebServerPrefersCustomWebPages {
	return NSUserDefaults.webPortalPrefersCustomWebPages;
}

@end
