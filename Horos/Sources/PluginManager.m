
#import "PluginManager.h"
#import "AppController.h"
#import "BrowserController.h"
#import "BLAuthentication.h"
#import "Notifications.h"
#import "NSFileManager+N2.h"
#import "NSString+SymlinksAndAliases.h"
#import "NSMutableDictionary+N2.h"
#import "PreferencesWindowController.h"
#import "N2Debug.h"
#import "NSString+SymlinksAndAliases.h"

static NSMutableDictionary		*plugins = nil, *pluginsDict = nil, *fileFormatPlugins = nil;
static NSMutableDictionary		*reportPlugins = nil, *pluginsBundleDictionnary = nil;

static NSMutableArray			*preProcessPlugins = nil;
static NSMenu					*fusionPluginsMenu = nil;
static NSMutableArray			*fusionPlugins = nil;
static NSMutableDictionary		*pluginsNames = nil;
static BOOL						ComPACSTested = NO, isComPACS = NO;

BOOL gPluginsAlertAlreadyDisplayed = NO;

@interface PluginManager (Dummy)

- (void)executeFilter:(id)sender;

@end

@implementation PluginManager

@synthesize downloadQueue;

+ (void) startProtectForCrashWithFilter: (id) filter
{
//    *(long*)0 = 0xDEADBEEF;
    
    for( NSBundle *bundle in [pluginsBundleDictionnary allValues])
    {
        if( [NSStringFromClass( [filter class]) isEqualToString: NSStringFromClass( [bundle principalClass])])
        {
            [PluginManager startProtectForCrashWithPath: [bundle bundlePath]];
           
//            *(long*)0 = 0xDEADBEEF;
            
            return;
        }
    }
    
    NSLog( @"***** unknown plugin - startProtectForCrashWithFilter - %@", NSStringFromClass( [filter principalClass]));
}

+ (void) startProtectForCrashWithPath: (NSString*) path
{
    // Match with AppController, ILCrashReporter
    [path writeToFile: @"/tmp/PluginCrashed" atomically: YES encoding: NSUTF8StringEncoding error: nil];
}

+ (void) endProtectForCrash
{
    // Match with AppController, ILCrashReporter
    [[NSFileManager defaultManager] removeItemAtPath: @"/tmp/PluginCrashed" error: nil];
}

+ (int) compareVersion: (NSString *) v1 withVersion: (NSString *) v2
{
	@try
	{
		NSArray *v1Tokens = [v1 componentsSeparatedByString: @"."];
		NSArray *v2Tokens = [v2 componentsSeparatedByString: @"."];
		int maxLen;
		
		if ( [v1Tokens count] > [v2Tokens count])
			maxLen = [v1Tokens count];
		else
			maxLen = [v2Tokens count];
		
		for (int i = 0; i < maxLen; i++)
		{
			int n1, n2;
			
			n1 = n2 = 0;
			
			if (i < [v1Tokens count])
				n1 = [[v1Tokens objectAtIndex: i] intValue];
			
			if (n1 <= 0)
				[NSException raise: @"compareVersion raised" format: @"compareVersion raised"];
			
			if (i < [v2Tokens count])
				n2 = [[v2Tokens objectAtIndex: i] intValue];
			
			if (n2 <= 0)
				[NSException raise: @"compareVersion raised" format: @"compareVersion raised"];
			
			if (n1 > n2)
				return 1;
			else if (n1 < n2)
				return -1;
		}
		
		return 0;
	}
	@catch (NSException *e)
	{
		return -1;
	}
	return -1;
}

+ (NSMutableDictionary*) plugins
{
	return plugins;
}

+ (NSMutableDictionary*) pluginsDict
{
	return pluginsDict;
}

+ (NSMutableDictionary*) fileFormatPlugins
{
	return fileFormatPlugins;
}

+ (NSMutableDictionary*) reportPlugins
{
	return reportPlugins;
}

+ (NSArray*) preProcessPlugins
{
	return preProcessPlugins;
}

+ (NSMenu*) fusionPluginsMenu
{
	return fusionPluginsMenu;
}

+ (NSArray*) fusionPlugins
{
	return fusionPlugins;
}

#ifdef OSIRIX_VIEWER

+(void)sortMenu:(NSMenu*)menu
{
    // [CH] Get an array of all menu items.
    NSArray* items = [menu itemArray];
    [menu removeAllItems];
    // [CH] Sort the array
    items = [items sortedArrayUsingDescriptors:[NSArray arrayWithObjects:[NSSortDescriptor sortDescriptorWithKey:@"title" ascending:YES selector:@selector(localizedCaseInsensitiveCompare:)], nil]];
    // [CH] ok, now set it back.
    for(NSMenuItem* item in items)
    {
        [menu addItem:item];
        /**
         * [CH] The following code fixes NSPopUpButton's confusion that occurs when
         * we sort this list. NSPopUpButton listens to the NSMenu's add notifications
         * and hides the first item. Sorting this blows it up.
         **/
        if(item.isHidden){
            [item setHidden: false];
        }
    }
}



+ (void) setMenus:(NSMenu*) filtersMenu :(NSMenu*) roisMenu :(NSMenu*) othersMenu :(NSMenu*) dbMenu
{
    [filtersMenu removeAllItems];
    [roisMenu removeAllItems];
    [othersMenu removeAllItems];
    [dbMenu removeAllItems];
	
	NSEnumerator *enumerator = [pluginsDict objectEnumerator];
	NSBundle *plugin;
	
	while ((plugin = [enumerator nextObject]))
	{
		NSString	*pluginName = [[plugin infoDictionary] objectForKey:@"CFBundleExecutable"];
		NSString	*pluginType = [[plugin infoDictionary] objectForKey:@"pluginType"];
		NSArray		*menuTitles = [[plugin infoDictionary] objectForKey:@"MenuTitles"];
		
        [PluginManager startProtectForCrashWithPath: [plugin bundlePath]];
        
		if( menuTitles)
		{
			if( [menuTitles count] > 1)
			{
				// Create a sub menu item
				
				NSMenu  *subMenu = [[[NSMenu alloc] initWithTitle: pluginName] autorelease];
				
				for( NSString *menuTitle in menuTitles)
				{
					NSMenuItem *item;
					
					if ([menuTitle isEqual:@"(-"])
					{
						item = [NSMenuItem separatorItem];
					}
					else
					{
						item = [[[NSMenuItem alloc] init] autorelease];
						[item setTitle:menuTitle];
						
						if( [pluginType rangeOfString: @"fusionFilter"].location != NSNotFound)
						{
							[fusionPlugins addObject:[item title]];
							[item setAction:@selector(endBlendingType:)];
						}
						else if( [pluginType rangeOfString: @"Database"].location != NSNotFound || [pluginType rangeOfString: @"Report"].location != NSNotFound)
						{
							[item setTarget: [BrowserController currentBrowser]];	//  browserWindow responds to DB plugins
							[item setAction:@selector(executeFilterDB:)];
						}
						else
						{
							[item setTarget:nil];	// FIRST RESPONDER !
							[item setAction:@selector(executeFilter:)];
						}
 					}
					
					[subMenu insertItem:item atIndex:[subMenu numberOfItems]];
				}
				
				id  subMenuItem;
				
				if( [pluginType rangeOfString: @"imageFilter"].location != NSNotFound)
				{
					if( [filtersMenu indexOfItemWithTitle: pluginName] == -1)
					{
						subMenuItem = [filtersMenu insertItemWithTitle:pluginName action:nil keyEquivalent:@"" atIndex:[filtersMenu numberOfItems]];
						[filtersMenu setSubmenu:subMenu forItem:subMenuItem];
					}
				}
				else if( [pluginType rangeOfString: @"roiTool"].location != NSNotFound)
				{
					if( [roisMenu indexOfItemWithTitle: pluginName] == -1)
					{
						subMenuItem = [roisMenu insertItemWithTitle:pluginName action:nil keyEquivalent:@"" atIndex:[roisMenu numberOfItems]];
						[roisMenu setSubmenu:subMenu forItem:subMenuItem];
					}
				}
				else if( [pluginType rangeOfString: @"fusionFilter"].location != NSNotFound)
				{
					if( [fusionPluginsMenu indexOfItemWithTitle: pluginName] == -1)
					{
						subMenuItem = [fusionPluginsMenu insertItemWithTitle:pluginName action:nil keyEquivalent:@"" atIndex:[fusionPluginsMenu numberOfItems]];
						[fusionPluginsMenu setSubmenu:subMenu forItem:subMenuItem];
					}
				}
				else if( [pluginType rangeOfString: @"Database"].location != NSNotFound)
				{
					if( [dbMenu indexOfItemWithTitle: pluginName] == -1)
					{
						subMenuItem = [dbMenu insertItemWithTitle:pluginName action:nil keyEquivalent:@"" atIndex:[dbMenu numberOfItems]];
						[dbMenu setSubmenu:subMenu forItem:subMenuItem];
					}
				} 
				else
				{
					if( [othersMenu indexOfItemWithTitle: pluginName] == -1)
					{
						subMenuItem = [othersMenu insertItemWithTitle:pluginName action:nil keyEquivalent:@"" atIndex:[othersMenu numberOfItems]];
						[othersMenu setSubmenu:subMenu forItem:subMenuItem];
					}
				}
                
                [subMenuItem setRepresentedObject:plugin];
			}
			else
			{
				// Create a menu item
				
				NSMenuItem *item = [[[NSMenuItem alloc] init] autorelease];
				
				[item setTitle: [menuTitles objectAtIndex: 0]];	//pluginName];
                [item setRepresentedObject:plugin];
				
				if( [pluginType rangeOfString: @"fusionFilter"].location != NSNotFound)
				{
					[fusionPlugins addObject:[item title]];
					[item setAction:@selector(endBlendingType:)];
				}
				else if( [pluginType rangeOfString: @"Database"].location != NSNotFound || [pluginType rangeOfString: @"Report"].location != NSNotFound)
				{
					[item setTarget:[BrowserController currentBrowser]];	//  browserWindow responds to DB plugins
					[item setAction:@selector(executeFilterDB:)];
				}
				else
				{
					[item setTarget:nil];	// FIRST RESPONDER !
					[item setAction:@selector(executeFilter:)];
				}
				
				if( [pluginType rangeOfString: @"imageFilter"].location != NSNotFound)
					[filtersMenu insertItem:item atIndex:[filtersMenu numberOfItems]];
				
				else if( [pluginType rangeOfString: @"roiTool"].location != NSNotFound)
					[roisMenu insertItem:item atIndex:[roisMenu numberOfItems]];
				
				else if( [pluginType rangeOfString: @"fusionFilter"].location != NSNotFound)
					[fusionPluginsMenu insertItem:item atIndex:[fusionPluginsMenu numberOfItems]];
				
				else if( [pluginType rangeOfString: @"Database"].location != NSNotFound)
					[dbMenu insertItem:item atIndex:[dbMenu numberOfItems]];
				
				else
					[othersMenu insertItem:item atIndex:[othersMenu numberOfItems]];
			}
		}
        
        [PluginManager endProtectForCrash];
	}
	
	if( [filtersMenu numberOfItems] < 1)
	{
		NSMenuItem *item = [[[NSMenuItem alloc] init] autorelease];
		[item setTitle:NSLocalizedString(@"No plugins available for this menu", nil)];
		[item setTarget:self];
		[item setAction:@selector(noPlugins:)]; 
		
		[filtersMenu insertItem:item atIndex:0];
	}
	
	if( [roisMenu numberOfItems] < 1)
	{
		NSMenuItem *item = [[[NSMenuItem alloc] init] autorelease];
		[item setTitle:NSLocalizedString(@"No plugins available for this menu", nil)];
		[item setTarget:self];
		[item setAction:@selector(noPlugins:)];
		
		[roisMenu insertItem:item atIndex:0];
	}
	
	if( [othersMenu numberOfItems] < 1)
	{
		NSMenuItem *item = [[[NSMenuItem alloc] init] autorelease];
		[item setTitle:NSLocalizedString(@"No plugins available for this menu", nil)];
		[item setTarget:self];
		[item setAction:@selector(noPlugins:)];
		
		[othersMenu insertItem:item atIndex:0];
	}
	
	if( [fusionPluginsMenu numberOfItems] <= 1)
	{
		NSMenuItem *item = [[[NSMenuItem alloc] init] autorelease];
		[item setTitle:NSLocalizedString(@"No plugins available for this menu", nil)];
		[item setTarget:self];
		[item setAction:@selector(noPlugins:)];
		
		[fusionPluginsMenu removeItemAtIndex: 0];
		[fusionPluginsMenu insertItem:item atIndex:0];
	}
	
	if( [dbMenu numberOfItems] < 1)
	{
		NSMenuItem *item = [[[NSMenuItem alloc] init] autorelease];
		[item setTitle:NSLocalizedString(@"No plugins available for this menu", nil)];
		[item setTarget:self];
		[item setAction:@selector(noPlugins:)];
		
		[dbMenu insertItem:item atIndex:0];
	}
	
    [PluginManager sortMenu: dbMenu];
    [PluginManager sortMenu: roisMenu];
    [PluginManager sortMenu: filtersMenu];
    [PluginManager sortMenu: othersMenu];
    
	NSEnumerator *pluginEnum = [plugins objectEnumerator];
	PluginFilter *pluginFilter;
	
	while( pluginFilter = [pluginEnum nextObject])
    {
        [PluginManager startProtectForCrashWithFilter: pluginFilter];
        
        @try
        {
            [pluginFilter setMenus];
        }
        @catch (NSException *e)
        {
            NSLog( @"***** exception in %s: %@", __PRETTY_FUNCTION__, e);
        }
        
        [PluginManager endProtectForCrash];
	}
}



- (id)init
{
	if (self = [super init])
	{
		// Set DefaultROINames *before* initializing plugins (which may change these)
		
		NSMutableArray *defaultROINames = [NSMutableArray array];
		
		[defaultROINames addObject:@"ROI 1"];
		[defaultROINames addObject:@"ROI 2"];
		[defaultROINames addObject:@"ROI 3"];
		[defaultROINames addObject:@"ROI 4"];
		[defaultROINames addObject:@"ROI 5"];
		
		[ViewerController setDefaultROINames: defaultROINames];
		
		[PluginManager discoverPlugins];
		
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(downloadNext:)
                                                     name:AppPluginDownloadInstallDidFinishNotification
                                                   object:nil];
	}
	return self;
}

+ (NSString*) pathResolved:(NSString*) inPath
{
    return [inPath stringByResolvingAlias];
}

+ (void) releaseInstanciedObjectsOfClass: (Class) class
{
    for( int i = 0; i < [preProcessPlugins count]; i++)
    {
        if( [[preProcessPlugins objectAtIndex: i] class] == class)
        {
            NSObject *filter = [preProcessPlugins objectAtIndex: i];
            
            if( [filter respondsToSelector: @selector(willUnload)])
                [filter performSelector: @selector(willUnload)];
            
            [preProcessPlugins removeObjectAtIndex: i];
            i--;
        }
    }
    
    for( NSString *key in [plugins allKeys])
    {
        if( [[plugins valueForKey: key] class] == class)
        {
            NSObject *filter = [plugins valueForKey: key];
            
            if( [filter respondsToSelector: @selector(willUnload)])
                [filter performSelector: @selector(willUnload)];
            
            [plugins removeObjectForKey: key];
        }
    }
}



+ (void) unloadPluginBundle:(NSBundle*) bundle
{
//    NSLog( @"--- will unloadplugin: %@", [bundle bundlePath]);
//    @try
//    {
//        [PluginManager startProtectForCrashWithPath: [bundle bundlePath]];
//        
//        Class filterClass = [bundle principalClass];
//                
//        [PluginManager releaseInstanciedObjectsOfClass: filterClass];
//        
//        [PreferencesWindowController removePluginPaneWithBundle: bundle];
//        
//        [pluginsNames removeObjectForKey: [[[bundle bundlePath] lastPathComponent] stringByDeletingPathExtension]];
//        [fileFormatPlugins removeObject: bundle];
//        [pluginsDict removeObject: bundle];
//        [reportPlugins removeObject: bundle];
//        
//        [PluginManager endProtectForCrash];
//        
//        if( [bundle unload] == NO) unload crash, if KVO Bindings is used in a plugin...
//        {
//            NSLog( @"***** failed to unload plugin: %@", [bundle bundlePath]);
//        }
//        else
//        {
//            for( NSString *key in [pluginsBundleDictionnary allKeys])
//            {
//                if( [pluginsBundleDictionnary valueForKey: key] == bundle)
//                {
//                    [pluginsBundleDictionnary removeObjectForKey: key];
//                    return;
//                }
//            }
//        }
//    }
//    @catch (NSException *e)
//    {
//        NSLog( @"***** exception in %s: %@", __PRETTY_FUNCTION__, e);
//    }
}


+ (void) unloadPluginWithName: (NSString*) name
{
    for( NSBundle *bundle in [pluginsBundleDictionnary allValues])
    {
        if( [[[[bundle bundlePath] lastPathComponent] stringByDeletingPathExtension] isEqualToString: name])
            [PluginManager unloadPluginBundle:bundle];
    }
}



+ (void) loadPluginBundle:(NSString*) path
{
        NSString *name = [path lastPathComponent];
        
        path = [path stringByDeletingLastPathComponent];
        
        [pluginsNames setValue: path forKey: [[name lastPathComponent] stringByDeletingPathExtension]];
        
        
        
        @try
        {
            NSString *pathResolved = [[path stringByAppendingPathComponent:name] stringByResolvingAlias];
            
            [PluginManager startProtectForCrashWithPath: pathResolved];
            
            
            
            NSBundle *plugin = [NSBundle bundleWithPath: pathResolved];
            
            if( plugin == nil)
                NSLog( @"**** Bundle opening failed for plugin: %@", [path stringByAppendingPathComponent:name]);
            else
            {
                if (![plugin load])
                {
                    NSLog( @"******* Bundle code loading failed for plugin %@", [path stringByAppendingPathComponent:name]);
                }
                else
                {
                    Class filterClass = [plugin principalClass];
                    
                    if( filterClass)
                    {
                        [pluginsBundleDictionnary setObject: plugin forKey: pathResolved];
                        
                        NSString *version = [[plugin infoDictionary] valueForKey: (NSString*) kCFBundleVersionKey];
                        
                        if( version == nil)
                        {
                            version = [[plugin infoDictionary] valueForKey: @"CFBundleShortVersionString"];
                        }
                        
                        NSLog( @"Loaded: %@, vers: %@ (%@)", [name stringByDeletingPathExtension], version, path);
                        
                        if( filterClass == NSClassFromString( @"ARGS"))
                        {
                            return;
                        }
                        
                        if ([[[plugin infoDictionary] objectForKey:@"pluginType"] rangeOfString:@"Pre-Process"].location != NSNotFound)
                        {
                            PluginFilter *filter = [filterClass filter];
                            [preProcessPlugins addObject: filter];
                        }
                        else if ([[plugin infoDictionary] objectForKey:@"FileFormats"])
                        {
                            NSEnumerator *enumerator = [[[plugin infoDictionary] objectForKey:@"FileFormats"] objectEnumerator];
                            NSString *fileFormat;
                            while (fileFormat = [enumerator nextObject])
                            {
                                //we will save the bundle rather than a filter.  Each file decode will require a separate decoder
                                [fileFormatPlugins setObject:plugin forKey:fileFormat];
                            }
                        }
                        else if ( [filterClass instancesRespondToSelector:@selector(filterImage:)])
                        {
                            NSArray *menuTitles = [[plugin infoDictionary] objectForKey:@"MenuTitles"];
                            PluginFilter *filter = [filterClass filter];
                            
                            if( menuTitles)
                            {
                                for( NSString *menuTitle in menuTitles)
                                {
                                    [plugins setObject:filter forKey:menuTitle];
                                    [pluginsDict setObject:plugin forKey:menuTitle];
                                }
                            }
                            
                            NSArray *toolbarNames = [[plugin infoDictionary] objectForKey:@"ToolbarNames"];
                            
                            if( toolbarNames)
                            {
                                for( NSString *toolbarName in toolbarNames)
                                {
                                    [plugins setObject:filter forKey:toolbarName];
                                    [pluginsDict setObject:plugin forKey:toolbarName];
                                }
                            }
                        }
                        
                        if ([[[plugin infoDictionary] objectForKey:@"pluginType"] rangeOfString: @"Report"].location != NSNotFound)
                        {
                            [reportPlugins setObject: plugin forKey:[[plugin infoDictionary] objectForKey:@"CFBundleExecutable"]];
                        }
                    }
                    else
                    {
                        NSLog( @"********* principal class not found for: %@ - %@", name, [plugin principalClass]);
                    }
                }
            }
            
            
            
            [PluginManager endProtectForCrash];
        }
        @catch( NSException *e)
        {
            NSLog( @"******** Plugin loading exception: %@", e);
        }
}



+ (void) loadOsiriXPluginAtPath:(NSString*) path
{
    [self loadPluginBundle:path];
}


+ (void) loadPluginAtPath: (NSString*) path
{
    NSString *name = [path lastPathComponent];
    
    
    if ([pluginsNames valueForKey: [[name lastPathComponent] stringByDeletingPathExtension]])
    {
        NSLog( @"***** Multiple plugins: %@", [name lastPathComponent]);
        
        NSString *message = NSLocalizedString(@"Warning! Multiple instances of the same plugin have been found. Only one instance will be loaded. Check the Plugin Manager (Plugins menu) for multiple identical plugins.", nil);
        
        message = [message stringByAppendingFormat:@"\r\r%@", [name lastPathComponent]];
        
        NSRunAlertPanel( NSLocalizedString(@"Plugins", nil), @"%@" , nil, nil, nil, message);
        
        return;
    }
    
    
    
    if ( [[name pathExtension] isEqualToString:@"osirixplugin"] )
    {
        [PluginManager loadOsiriXPluginAtPath:path];
    }
    else if ( [[name pathExtension] isEqualToString:@"plugin"] )
    {
        //[PluginManager loadUnknownPluginAtPath:path];
    }
}



+ (void) discoverPlugins
{
	@try
	{
		NSString	*appSupport = @"Library/Application Support/hera/Plugins/";
		NSString	*appPath = [[NSBundle mainBundle] builtInPlugInsPath];
		NSString	*userPath = [NSHomeDirectory() stringByAppendingPathComponent:appSupport];
		NSString	*sysPath = [@"/" stringByAppendingPathComponent:appSupport];
		NSArray* paths = [NSArray arrayWithObjects: [NSNull null], appPath, userPath, sysPath, nil]; // [NSNull null] is a placeholder for launch parameters load commands
		
        for( NSBundle *bundle in [pluginsBundleDictionnary allValues])
            [PluginManager unloadPluginBundle: bundle];
        
		[plugins release];
		[pluginsDict release];
		[fileFormatPlugins release];
		[preProcessPlugins release];
		[reportPlugins release];
		[fusionPlugins release];
		[fusionPluginsMenu release];
		[pluginsNames  release];
        [pluginsBundleDictionnary release];
        
        pluginsBundleDictionnary = [[NSMutableDictionary alloc] init];
		plugins = [[NSMutableDictionary alloc] init];
		pluginsDict = [[NSMutableDictionary alloc] init];
		fileFormatPlugins = [[NSMutableDictionary alloc] init];
		preProcessPlugins = [[NSMutableArray alloc] initWithCapacity:0];
		reportPlugins = [[NSMutableDictionary alloc] init];
		pluginsNames = [[NSMutableDictionary alloc] init];
		fusionPlugins = [[NSMutableArray alloc] initWithCapacity:0];
		
		fusionPluginsMenu = [[NSMenu alloc] initWithTitle:@""];
		[fusionPluginsMenu insertItemWithTitle:NSLocalizedString(@"Select a fusion plug-in", nil) action:nil keyEquivalent:@"" atIndex:0];
		
		NSLog( @"|||||||||||||||||| Plugins loading START ||||||||||||||||||");
		
        NSString *pluginCrash = [[[NSFileManager defaultManager] userApplicationSupportFolderForApp] stringByAppendingPathComponent:@"Plugin_Loading"];
        if ([[NSFileManager defaultManager] fileExistsAtPath: pluginCrash] && ![[NSUserDefaults standardUserDefaults] boolForKey:@"DoNotDeleteCrashingPlugins"])
        {
            NSString *pluginCrashPath = [NSString stringWithContentsOfFile: pluginCrash encoding: NSUTF8StringEncoding error: nil];
            
            int result = NSRunInformationalAlertPanel(NSLocalizedString(@"Horos crashed", nil), NSLocalizedString(@"Previous crash is maybe related to a plugin.\r\rShould I remove this plugin (%@)?", nil), NSLocalizedString(@"Delete Plugin",nil), NSLocalizedString(@"Continue",nil), nil, [pluginCrashPath lastPathComponent]);
            
            if( result == NSAlertDefaultReturn) // Delete Plugin
            {
                NSError *error = nil;
                [[NSFileManager defaultManager] removeItemAtPath: pluginCrashPath error: &error];
                
                if( error)
                    NSLog( @"**** Cannot Delete File : Crashing Plugin Delete Error: %@", error);
            }
            
            [[NSFileManager defaultManager] removeItemAtPath: pluginCrash error: nil];
        }
        
        NSMutableArray* pathsOfPluginsToLoad = [NSMutableArray array];
        NSMutableArray* dontLoadOtherWithTheseNames = [NSMutableArray array];
        
        for (id path in paths)
            @try {
                NSArray* donotloadnames = nil;
                if (![path isKindOfClass:[NSNull class]]) {
                    donotloadnames = [[NSString stringWithContentsOfFile:[path stringByAppendingPathComponent:@"DoNotLoad.txt"] usedEncoding:NULL error:NULL] componentsSeparatedByCharactersInSet:[NSCharacterSet newlineCharacterSet]];
                    if ([donotloadnames containsObject:@"*"])
                        break;
                }

                NSEnumerator* e = nil;
                if ([path isKindOfClass:[NSString class]])
                {
                    NSArray<NSString *>* pluginsInDir = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:path error:NULL];
                    e = [[pluginsInDir filteredArrayUsingPredicate:[NSPredicate predicateWithBlock:^BOOL(NSString* plugin, NSDictionary* bindings) {
                        BOOL listed = [dontLoadOtherWithTheseNames containsObject:plugin];
                        if (listed)
                            NSLog(@"Won't load %@ from %@ in favor of %@", plugin, path, [[pathsOfPluginsToLoad filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"lastPathComponent = %@", plugin]] lastObject]);
                        return !listed;
                    }]] objectEnumerator];
                }
                else if (path == [NSNull null])
                {
                    path = @"/";
                    NSMutableArray* cl = [NSMutableArray array];
                    NSArray* args = [[NSProcessInfo processInfo] arguments];
                    for (NSInteger i = 0; i < [args count]; ++i)
                        if ([[args objectAtIndex:i] isEqualToString:@"--LoadPlugin"] && [args count] > i+1) {
                            NSString* pluginpath = [args objectAtIndex:++i];
                            [cl addObject:pluginpath];
                            [dontLoadOtherWithTheseNames addObject:pluginpath.lastPathComponent];
                        }
                    e = [cl objectEnumerator];
                }
                
                NSString* name;
                while (name = [e nextObject])
                    if ([donotloadnames containsObject:[name stringByDeletingPathExtension]] == NO)
                        [pathsOfPluginsToLoad addObject:[[path stringByAppendingPathComponent:name] stringByResolvingSymlinksAndAliases]];
            } @catch (NSException* e) {
                N2LogExceptionWithStackTrace(e);
            }
        
//        NSLog(@"paths: %@", pathsOfPluginsToLoad);
        
        // some plugins require other plugins to be loaded before them
        for (__block NSInteger i = pathsOfPluginsToLoad.count-1; i >= 0; --i) {
            
            
            NSBundle* bundle = [NSBundle bundleWithPath:[pathsOfPluginsToLoad objectAtIndex:i]];
            NSString* name = [bundle.infoDictionary objectForKey:@"CFBundleName"];
            if (!name) name = [[[pathsOfPluginsToLoad objectAtIndex:i] lastPathComponent] stringByDeletingPathExtension];
//            
//            NSLog(@"for %@", name);
            
            // list of requirements
            for (NSString* req in [bundle.infoDictionary objectForKey:@"Requirements"]) {
                // make sure they're loaded before this plugin
                NSIndexSet* is = [pathsOfPluginsToLoad indexesOfObjectsPassingTest:^BOOL(id obj, NSUInteger idx, BOOL *stop) {
                    NSBundle* bundle = [NSBundle bundleWithPath:obj];
                    NSString* name = [bundle.infoDictionary objectForKey:@"CFBundleName"];
                    if (!name) name = [[obj lastPathComponent] stringByDeletingPathExtension];
                    return [name isEqualToString:req];
                }];
                if (!is.count)
                    NSLog(@"Warning: plugin requirement %@ not available for %@", req, name); // we actually may decide not to load this plugin, since it requires something that apparently isn't available, but hopefully it'll just raise an exception and end up not being loaded...
                [is enumerateIndexesUsingBlock:^(NSUInteger idx, BOOL *stop) {
                    if (idx > i) {
                        id o = [[[pathsOfPluginsToLoad objectAtIndex:idx] retain] autorelease];
                        [pathsOfPluginsToLoad removeObjectAtIndex:idx];
                        [pathsOfPluginsToLoad insertObject:o atIndex:i++];
                    }
                }];
            }
        }
        
        for (id path in pathsOfPluginsToLoad)
            [PluginManager loadPluginAtPath:path];
		
        NSLog( @"|||||||||||||||||| Plugins loading END ||||||||||||||||||");
	}
	@catch (NSException * e)
	{
        N2LogExceptionWithStackTrace(e);
	}
}


-(void) noPlugins:(id) sender
{
    [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:@"opendicom.com"]];
}


#endif

@end
