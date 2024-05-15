
#import <Cocoa/Cocoa.h>
#import <WebKit/WebKit.h>
#import "PluginManager.h"

/** \brief Window Controller for PluginFilter management */

@interface PluginsTableView : NSTableView
{

}
@end

@interface PluginManagerController : NSWindowController <NSURLDownloadDelegate, WebPolicyDelegate>
{

    IBOutlet NSMenu	*filtersMenu;
	IBOutlet NSMenu	*roisMenu;
	IBOutlet NSMenu	*othersMenu;
	IBOutlet NSMenu	*dbMenu;

	NSMutableArray* plugins;
	IBOutlet NSArrayController* pluginsArrayController;
	IBOutlet PluginsTableView *pluginTable;
	
	IBOutlet NSTabView *tabView;
	IBOutlet NSTabViewItem *installedPluginsTabViewItem, *osirixPluginsTabViewItem, *horosPluginsTabViewItem;
	
    IBOutlet WebView *osirixPluginWebView, *horosPluginWebView;
    IBOutlet NSPopUpButton *osirixPluginListPopUp, *horosPluginListPopUp;
	NSString *osirixPluginDownloadURL, *horosPluginDownloadURL;
    BOOL osiriXPluginHorosCompatibility;
    IBOutlet NSButton *osirixPluginDownloadButton, *horosPluginDownloadButton;
    
    IBOutlet NSTextField *osirixPluginStatusTextField, *horosPluginStatusTextField;
    IBOutlet NSProgressIndicator *osirixPluginStatusProgressIndicator, *horosPluginStatusProgressIndicator;
    
    IBOutlet NSBox *validatedInHorosBox;
    IBOutlet NSBox *NOTvalidatedInHorosBox;
    IBOutlet NSTextField *protectedModeLabel;
    
    NSMutableDictionary *downloadingPlugins;
}

- (NSMutableArray*)plugins;
- (NSArray*)availabilities;
- (IBAction)modifiyActivation:(id)sender;
- (IBAction)delete:(id)sender;
- (IBAction)modifiyAvailability:(id)sender;
- (IBAction)loadPlugins:(id)sender;
- (void)refreshPluginList;

- (IBAction) changeOsiriXPluginWebView:(id)sender;
- (IBAction) changeHorosPluginWebView:(id)sender;

@end
