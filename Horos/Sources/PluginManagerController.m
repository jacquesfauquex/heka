#import "PluginManagerController.h"
//#import <Message/NSMailDelivery.h>
#import "WaitRendering.h"
#import "Notifications.h"
#import "PreferencesWindowController.h"
#import "ThreadsManager.h"
#import "NSThread+N2.h"
#import "AppController.h"



static NSArray *CachedOsiriXPluginsList = nil;
static NSDate *CachedOsiriXPluginsListDate = nil;

static NSArray *CachedHorosPluginsList = nil;
static NSDate *CachedHorosPluginsListDate = nil;



@implementation PluginsTableView

- (void)keyDown:(NSEvent *)event
{
    if( [[event characters] length] == 0)
        return;
    
	unichar c = [[event characters] characterAtIndex:0];
	
    if ( (c == NSDeleteFunctionKey || c == NSDeleteCharacter || c == NSBackspaceCharacter || c == NSDeleteCharFunctionKey) && [self selectedRow] >= 0 && [self numberOfRows] > 0 )
    {
		[(PluginManagerController*)[self delegate] delete:self];
    }
	else
    {
		 [super keyDown:event];
    }
}

@end



@implementation PluginManagerController


- (void) WebViewProgressStartedNotification: (NSNotification*) n
{
    NSProgressIndicator *statusProgressIndicator = nil;
    
    if (osirixPluginWebView == [n object])
    {
        statusProgressIndicator = osirixPluginStatusProgressIndicator;
    }
    else
    {
        statusProgressIndicator = horosPluginStatusProgressIndicator;
    }
    
    [statusProgressIndicator setHidden: NO];
	[statusProgressIndicator startAnimation: self];
    
    [[self window] display];
}


- (void) WebViewProgressFinishedNotification: (NSNotification*) n
{
    NSProgressIndicator *statusProgressIndicator = nil;
    
    if (osirixPluginWebView == [n object])
    {
        statusProgressIndicator = osirixPluginStatusProgressIndicator;
    }
    else
    {
        statusProgressIndicator = horosPluginStatusProgressIndicator;
    }
    
    [statusProgressIndicator setHidden: YES];
	[statusProgressIndicator stopAnimation: self];
    
    [[self window] display];
}


- (id)init
{
	self = [super initWithWindowNibName:@"PluginManager"];
	
    downloadingPlugins = [[NSMutableDictionary dictionary] retain];
    
	plugins = [[NSMutableArray arrayWithArray:[PluginManager pluginsList]] retain];
	 
	return self;
}


- (void)windowDidBecomeMain:(NSNotification *)notification
{
}


- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver: self]; 
     
	[plugins release];
    
    [downloadingPlugins release];
	
	[super dealloc];
}

#pragma mark -
#pragma mark installed

- (NSMutableArray*)plugins;
{
	return plugins;
}


- (NSArray*) availabilities;
{
	return [PluginManager availabilities];
}


- (IBAction)modifiyActivation:(id)sender;
{
	NSArray *pluginsList = [pluginsArrayController arrangedObjects];
	NSString *pluginName = [[pluginsList objectAtIndex:[pluginTable clickedRow]] objectForKey:@"name"];
	BOOL pluginIsActive = [[[pluginsList objectAtIndex:[pluginTable clickedRow]] objectForKey:@"active"] boolValue];

	if(!pluginIsActive)
	{
		[PluginManager deactivatePluginWithName:pluginName];
	}
	else
	{
		[PluginManager activatePluginWithName:pluginName];
	}
	
	[self refreshPluginList];
	[pluginTable selectRowIndexes: [NSIndexSet indexSetWithIndex: [pluginTable clickedRow]] byExtendingSelection:NO];
}


- (IBAction) delete:(id)sender;
{
    if ([[pluginsArrayController arrangedObjects] count] == 0)
        return;
    
	if( NSRunInformationalAlertPanel(NSLocalizedString(@"Delete a plugin", nil),
									 NSLocalizedString(@"Are you sure you want to delete the selected plugin?", nil),
									 NSLocalizedString(@"OK",nil),
									 NSLocalizedString(@"Cancel",nil),
									 nil) == NSAlertDefaultReturn)
	{
		NSArray *pluginsList = [pluginsArrayController arrangedObjects];
		NSString *pluginName = [[pluginsList objectAtIndex:[pluginTable selectedRow]] objectForKey:@"name"];
		NSString *availability = [[pluginsList objectAtIndex:[pluginTable selectedRow]] objectForKey:@"availability"];
		BOOL pluginIsActive = [[[pluginsList objectAtIndex:[pluginTable selectedRow]] objectForKey:@"active"] boolValue];
		
		[PluginManager deletePluginWithName:pluginName
                               availability:availability
                                   isActive: pluginIsActive];
        
		[self refreshPluginList];
	}
}


- (IBAction)modifiyAvailability:(id)sender;
{
	NSArray *pluginsList = [pluginsArrayController arrangedObjects];
	NSString *pluginName = [[pluginsList objectAtIndex:[pluginTable clickedRow]] objectForKey:@"name"];
	
	[PluginManager changeAvailabilityOfPluginWithName:pluginName to:[[sender selectedCell] title]];
	
	[self refreshPluginList]; // needed to restore the availability menu in case the user did provided a good admin password
}


- (IBAction)loadPlugins:(id)sender;
{
	[PluginManager setMenus:filtersMenu :roisMenu :othersMenu :dbMenu];
}


- (void)windowWillClose:(NSNotification *)aNotification;
{
	[[self window] setAcceptsMouseMovedEvents: NO];
	
    @try
    {
        [self refreshPluginList];
    }
    @catch (NSException * e)
    {
        NSLog( @"windowwillClose exception pluginmanagercontroller: %@", e);
    }
}



- (IBAction) showWindow:(id)sender;
{
    if ([[self window] isVisible])
    {
        [[self window] makeKeyAndOrderFront:nil];
        return;
    }

}


- (void) awakeFromNib
{
    [super awakeFromNib];
}


- (void)refreshPluginList;
{
	NSIndexSet *selectedIndexes = [pluginTable selectedRowIndexes];
	
    [PluginManager setMenus:filtersMenu :roisMenu :othersMenu :dbMenu];
	
	[self willChangeValueForKey:@"plugins"];
	[plugins removeAllObjects];
	[plugins addObjectsFromArray:[PluginManager pluginsList]];
	[self didChangeValueForKey:@"plugins"];
	
	[pluginTable selectRowIndexes:selectedIndexes byExtendingSelection:NO];
}


#pragma mark NSTabView Delegate methods

- (void)tabView:(NSTabView *)tabView willSelectTabViewItem:(NSTabViewItem *)tabViewItem
{
	if([tabViewItem isEqualTo:installedPluginsTabViewItem])
		[self refreshPluginList];
}


#pragma mark download


- (void) fakeThread: (NSString*) downloadedFilePath
{
    NSAutoreleasePool *pool = [NSAutoreleasePool new];
    
    BOOL downloading = YES;
    
    while( downloading)
    {
        @synchronized( downloadingPlugins)
        {
            if( [downloadingPlugins objectForKey: downloadedFilePath] == nil)
            {
                downloading = NO;
            }
            
            [NSThread sleepForTimeInterval: 1];
        }
    }
    
    [pool release];
}



#pragma mark WebPolicyDelegate Protocol methods

- (void)webView:(WebView *)sender decidePolicyForNavigationAction:(NSDictionary *)actionInformation request:(NSURLRequest *)request frame:(WebFrame *)frame decisionListener:(id<WebPolicyDecisionListener>)listener;
{
	if(![sender isEqualTo:osirixPluginWebView] && ![sender isEqualTo:horosPluginWebView])
    {
        [listener use];
    }

	if([[actionInformation valueForKey:WebActionNavigationTypeKey] intValue]==WebNavigationTypeLinkClicked)
	{
		[[NSWorkspace sharedWorkspace] openURL:[request URL]];
	}
	else if([[actionInformation valueForKey:WebActionNavigationTypeKey] intValue]==WebNavigationTypeFormSubmitted)
	{
		[self sendPluginSubmission:[[request URL] absoluteString]];
	}
	else
	{
		[listener use];
	}
}

@end
