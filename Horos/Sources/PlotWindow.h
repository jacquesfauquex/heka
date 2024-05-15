


#import <AppKit/AppKit.h>
#import "ROI.h"
#import "PlotView.h"

/** \brief  Window Controller for Plot */

@interface PlotWindow : NSWindowController {
	
	ROI						*curROI;
	
	float					*data, maxValue, minValue;
	long					dataSize;
	
	IBOutlet PlotView		*plot;
	IBOutlet NSTextField	*maxX, *minY, *maxY, *sizeT;
}

- (id) initWithROI: (ROI*) iroi;
- (ROI*) curROI;
@end
