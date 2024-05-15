
#import "DicomDatabase.h"
#import "QueryLogController.h"
#import "BrowserController.h"

@implementation QueryLogController

- (void)awakeFromNib
{
	[self setManagedObjectContext: [BrowserController.currentBrowser.database managedObjectContext]];
	[self setAutomaticallyPreparesContent: YES];
    
	[self fetch: self];
	
	[self setSortDescriptors:[NSArray arrayWithObject: [[[NSSortDescriptor alloc] initWithKey:@"startTime" ascending:NO] autorelease]]];
}

- (IBAction)nothing:(id)sender
{

}
@end
