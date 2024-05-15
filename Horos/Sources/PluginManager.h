


#import <Cocoa/Cocoa.h>
#import "PluginFilter.h"
/** \brief Mangages PluginFilter loading */
@interface PluginManager : NSObject
{
	NSMutableArray *downloadQueue;
	BOOL startedUpdateProcess;
}

@property(retain,readwrite) NSMutableArray *downloadQueue;

+ (int) compareVersion: (NSString *) v1 withVersion: (NSString *) v2;
+ (NSMutableDictionary*) plugins;
+ (NSMutableDictionary*) pluginsDict;
+ (NSMutableDictionary*) fileFormatPlugins;
+ (NSMutableDictionary*) reportPlugins;
+ (NSArray*) preProcessPlugins;
+ (NSMenu*) fusionPluginsMenu;
+ (NSArray*) fusionPlugins;

+ (void) startProtectForCrashWithFilter: (id) filter;
+ (void) startProtectForCrashWithPath: (NSString*) path;
+ (void) endProtectForCrash;

#ifdef OSIRIX_VIEWER

+ (NSString*) pathResolved:(NSString*) inPath __deprecated;
+ (void)discoverPlugins;
+ (void) unloadPluginWithName: (NSString*) name;
+ (void) loadPluginAtPath: (NSString*) path;
+ (void) setMenus:(NSMenu*) filtersMenu :(NSMenu*) roisMenu :(NSMenu*) othersMenu :(NSMenu*) dbMenu;
+ (NSArray*)pluginsList;
+ (void)createDirectory:(NSString*)directoryPath;
+ (NSArray*)availabilities;

- (void)displayUpdateMessage:(NSDictionary*)messageDictionary;

#endif

@end
