#import "options.h"

#import "OSI3DPreferencePane.h"
#import "VTKView.h"

@implementation OSI3DPreferencePanePref

- (id) initWithBundle:(NSBundle *)bundle
{
	if( self = [super init])
	{
		NSNib *nib = [[[NSNib alloc] initWithNibNamed: @"OSI3DPreferencePanePref" bundle: nil] autorelease];
		[nib instantiateWithOwner:self topLevelObjects:&_tlos];
		
		[self setMainView: [mainWindow contentView]];
		[self mainViewDidLoad];
        
        [[NSUserDefaultsController sharedUserDefaultsController] addObserver:self forKeyPath: @"values.MAPPERMODEVR" options:NSKeyValueObservingOptionNew context:NULL];
	}
	
	return self;
}

-(void)observeValueForKeyPath:(NSString*)keyPath ofObject:(id)object change:(NSDictionary*)change context:(void*)context
{
	if (object == [NSUserDefaultsController sharedUserDefaultsController])
    {
		if ([keyPath isEqualToString: @"values.MAPPERMODEVR"])
        {
            if( [[NSUserDefaults standardUserDefaults] boolForKey: @"MAPPERMODEVR"])
            {
                unsigned long vramMB = [VTKView VRAMSizeForDisplayID: [[[[mainWindow screen] deviceDescription] objectForKey: @"NSScreenNumber"] intValue]];
            }
        }
    }
}

- (void) dealloc
{
	NSLog(@"dealloc OSI3DPreferencePanePref");
	
    [[NSUserDefaultsController sharedUserDefaultsController] removeObserver:self forKeyPath: @"values.MAPPERMODEVR"];
    
    [_tlos release]; _tlos = nil;
    
	[super dealloc];
}

- (void) willUnselect
{
	[[[self mainView] window] makeFirstResponder: nil];
    
}

- (void) mainViewDidLoad
{
}

@end
