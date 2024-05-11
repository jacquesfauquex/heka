#import "NSUserDefaults+OsiriX.h"
#import "NSUserDefaultsController+N2.h"


@interface NSUserDefaultsController (OsiriX)
@end

@interface NSUserDefaultsController (Deprecated)

extern NSString* const OsirixWebServerUsesWeasisDefaultsKey __deprecated;
extern NSString* const OsirixWadoServerActiveDefaultsKey __deprecated;
extern NSString* const OsirixWebServerPrefersFlashDefaultsKey __deprecated;
extern NSString* const OsirixWebServerPrefersCustomWebPagesKey __deprecated;

+(BOOL)WebServerUsesWeasis __deprecated;
+(BOOL)WadoServerActive __deprecated;
+(BOOL)WebServerPrefersFlash __deprecated;
+(BOOL)WebServerPrefersCustomWebPages __deprecated;

@end
