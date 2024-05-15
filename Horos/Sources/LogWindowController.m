#import "LogWindowController.h"
#import "BrowserController.h"
#import "DicomDatabase.h"
#import "NSUserDefaults+OsiriX.h"

@implementation LogWindowController

- (IBAction) export:(id) sender
{
	NSArray *a = nil;
	NSString *filename = nil;
	
	switch( [sender tag])
	{
		case 1: a = [receive arrangedObjects]; filename = @"ReceiveLog.csv"; break;
		case 2: a = [send arrangedObjects]; filename = @"SendLog.csv"; break;
		case 3: a = [move arrangedObjects]; filename = @"MoveLog.csv"; break;
		case 4: a = [web arrangedObjects]; filename = @"WebLog.csv"; break;
	}
	
	NSMutableString *csv = [NSMutableString string];
	
	NSArray *logEntries = [[[[BrowserController.currentBrowser.database.managedObjectModel entitiesByName] objectForKey:@"LogEntry"] attributesByName] allKeys];
	
	// HEADER
	NSMutableString *line = [NSMutableString string];
	for( NSString *name in logEntries)
	{
		[line appendString: name];
		[line appendString: @","];
	}
	[line deleteCharactersInRange: NSMakeRange( [line length]-1, 1)];
	[csv appendString: line];
	[csv appendString: @"\n"];
	
	for( NSManagedObject *o in a)
	{
		line = [NSMutableString string];
		for( NSString *name in logEntries)
		{
			if( [o valueForKey: name])
			{
				if( [[o valueForKey: name] isKindOfClass: [NSDate class]])
					[line appendString:[[[NSUserDefaults dateTimeFormatter] stringFromDate:[o valueForKey:name]] stringByReplacingOccurrencesOfString: @"," withString: @" "]];
				else
					[line appendString: [[[o valueForKey: name] description] stringByReplacingOccurrencesOfString: @"," withString: @" "]];
			}
			else
				[line appendString: @"void"];
				
			[line appendString: @","];
		}
		[line deleteCharactersInRange: NSMakeRange( [line length]-1, 1)];
		
		[csv appendString: line];
		[csv appendString: @"\n"];
	}
	
	NSSavePanel *savePanel = [NSSavePanel savePanel];
	
	[savePanel setAllowedFileTypes:@[@"csv"]];
	
    savePanel.nameFieldStringValue = filename;
    
    [savePanel beginWithCompletionHandler:^(NSInteger result) {
        if (result != NSFileHandlingPanelOKButton)
            return;
        
        [csv writeToURL: [savePanel URL] atomically: YES encoding:NSUTF8StringEncoding error:NULL];
    }];
}

-(id) init
{
	return  [super initWithWindowNibName:@"LogWindow"];
}

-(void) awakeFromNib
{
	[[self window] setFrameAutosaveName:@"LogWindow"];
}

- (void) dealloc
{
	NSLog( @"LogWindowController dealloc");
	
	[super dealloc];
}

-(IBAction) showWindow:(id) sender
{
	[super showWindow: sender];
	
	if( [[BrowserController currentBrowser] isNetworkLogsActive] == NO)
	{
		if( NSRunInformationalAlertPanel( NSLocalizedString( @"Network Logs", nil), NSLocalizedString( @"Network Logs are currently off. Do you want to activate them?\r\rYou can activate or de-activate them in the Preferences - Listener window.", nil), NSLocalizedString( @"Activate", nil), NSLocalizedString( @"Cancel", nil), nil) == 1)
		{
			[[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"NETWORKLOGS"];
			[[BrowserController currentBrowser] setNetworkLogs];
		}
	}
}

@end
