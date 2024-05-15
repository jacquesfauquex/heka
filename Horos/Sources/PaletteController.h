

#import <Cocoa/Cocoa.h>
#import "DCMView.h"
#import "ROI.h"
@class ViewerController;

/** \brief  Window Controller for ROI palette */

@interface PaletteController : NSWindowController <NSWindowDelegate>
{
	ViewerController			*viewer;
	IBOutlet NSSegmentedControl	*modeControl;
	IBOutlet NSSlider			*sizeSlider;
	IBOutlet NSTextField		*sliderTextValue;
}
- (id) initWithViewer:(ViewerController*) v;
- (IBAction)changeBrushSize:(id)sender;
- (IBAction)changeMode:(id)sender;
@end
