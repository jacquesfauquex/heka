#import "OSIViewerPreferencePanePref.h"
#import "AppController.h"
#import "ViewerController.h"

@implementation OSIViewerPreferencePanePref

static NSString* UserDefaultsObservingContext = @"UserDefaultsObservingContext";

- (id) initWithBundle:(NSBundle *)bundle
{
	if( self = [super init])
	{
		NSNib *nib = [[[NSNib alloc] initWithNibNamed: @"OSIViewerPreferencePanePref" bundle: nil] autorelease];
		[nib instantiateWithOwner:self topLevelObjects:&_tlos];
		
		[self setMainView: [mainWindow contentView]];
		[self mainViewDidLoad];
        
        [[NSUserDefaultsController sharedUserDefaultsController] addObserver:self forKeyPath:@"values.ReserveScreenForDB" options:0 context:UserDefaultsObservingContext];
        [[NSUserDefaultsController sharedUserDefaultsController] addObserver:self forKeyPath:@"values.AUTOTILING" options:0 context:UserDefaultsObservingContext];
        [[NSUserDefaultsController sharedUserDefaultsController] addObserver:self forKeyPath:@"values.UseFloatingThumbnailsList" options:0 context:UserDefaultsObservingContext];
	}
	
	return self;
}

- (void) dealloc
{
	NSLog(@"dealloc OSIViewerPreferencePanePref");
    [[NSUserDefaultsController sharedUserDefaultsController] removeObserver:self forKeyPath:@"values.ReserveScreenForDB"];
    [[NSUserDefaultsController sharedUserDefaultsController] removeObserver:self forKeyPath:@"values.AUTOTILING"];
    [[NSUserDefaultsController sharedUserDefaultsController] removeObserver:self forKeyPath:@"values.UseFloatingThumbnailsList"];
    
    [_tlos release]; _tlos = nil;
    
    [super dealloc];
}

- (void) observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if (context != UserDefaultsObservingContext)
        return [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
    
    if( [keyPath isEqualToString: @"values.ReserveScreenForDB"])
    {
        [self willChangeValueForKey:@"screensThumbnail"];
        [self didChangeValueForKey:@"screensThumbnail"];
    }
    
    if( [keyPath isEqualToString: @"values.AUTOTILING"])
    {
        if( [[NSUserDefaults standardUserDefaults] boolForKey: @"AUTOTILING"])
            [[NSUserDefaults standardUserDefaults] setInteger:0 forKey: @"WINDOWSIZEVIEWER"];
    }
    
    if( [keyPath isEqualToString: @"values.UseFloatingThumbnailsList"])
    {
        [ViewerController closeAllWindows];
        [[NSUserDefaults standardUserDefaults] setBool: YES forKey: @"SeriesListVisible"];
    }
}

- (void) willSelect
{
}

- (void) willUnselect
{
	[[[self mainView] window] makeFirstResponder: nil];
}

- (void) mainViewDidLoad
{
	if( [[NSUserDefaults standardUserDefaults] boolForKey:@"is12bitPluginAvailable"] == NO)
		[[NSUserDefaults standardUserDefaults] setBool: NO forKey:@"automatic12BitTotoku"];
}

- (AppController*) appController
{
	return [AppController sharedAppController];
}
@end
