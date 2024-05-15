#import "OSICDPreferencePanePref.h"

@implementation OSICDPreferencePanePref

- (id) initWithBundle:(NSBundle *)bundle
{
	if( self = [super init])
	{
		NSNib *nib = [[[NSNib alloc] initWithNibNamed: @"OSICDPreferencePanePref" bundle: nil] autorelease];
		[nib instantiateWithOwner:self topLevelObjects:&_tlos];
		
		[self setMainView: [mainWindow contentView]];
		[self mainViewDidLoad];
        
        if( [[NSUserDefaults standardUserDefaults] stringForKey: @"SupplementaryBurnPath"].length <= 1)
            [[NSUserDefaults standardUserDefaults] setObject:@"/~Documents/FolderToBurn" forKey:@"SupplementaryBurnPath"];
        
        if( [[NSFileManager defaultManager] fileExistsAtPath: [[[NSUserDefaults standardUserDefaults] stringForKey: @"SupplementaryBurnPath"] stringByExpandingTildeInPath]] == NO)
            [[NSUserDefaults standardUserDefaults] setBool: NO forKey: @"BurnSupplementaryFolder"];
	}
	
	return self;
}


- (void) dealloc
{
    NSLog(@"dealloc OSICDPreferencePanePref");
    
    [_tlos release]; _tlos = nil;
	
	[super dealloc];
}

-(void) willUnselect
{
	[[[self mainView] window] makeFirstResponder: nil];
}

- (IBAction)chooseSupplementaryBurnPath: (id)sender
{
	NSOpenPanel *openPanel = [NSOpenPanel openPanel];
	[openPanel setCanChooseDirectories: YES];
	[openPanel setCanChooseFiles: NO];
    
    [openPanel beginWithCompletionHandler:^(NSInteger result) {
        if (result != NSFileHandlingPanelOKButton)
            return;
        
        [[NSUserDefaults standardUserDefaults] setObject:openPanel.URL.path forKey:@"SupplementaryBurnPath"];
    }];
}

@end
