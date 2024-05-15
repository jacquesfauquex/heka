

#import <Cocoa/Cocoa.h>
#import "DCMView.h"
#import "DCMPix.h"
#import "ROI.h"
#import "ViewerController.h"


/** \brief  Window Controller for ROI management */

@interface ROIManagerController : NSWindowController
{
		ViewerController			*viewer;
		IBOutlet NSTableView		*tableView;
		float						pixelSpacingZ;
}

/** Default initializer */
- (id) initWithViewer:(ViewerController*) v;
/** Delete ROI */
- (IBAction)deleteROI:(id)sender;
	// Table view data source methods
- (NSInteger)numberOfRowsInTableView:(NSTableView *)aTableView;
- (id)tableView:(NSTableView *)aTableView
    objectValueForTableColumn:(NSTableColumn *)aTableColumn
			row:(NSInteger)rowIndex;
- (void) roiListModification :(NSNotification*) note;
- (void) fireUpdate: (NSNotification*) note;
@end
