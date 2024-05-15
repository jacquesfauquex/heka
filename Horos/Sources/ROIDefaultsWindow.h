


#import "ROI.h"
#import "MyNSTextView.h"
#import "ViewerController.h"

/** \brief  Window Controller for ROI defaults */

@interface ROIDefaultsWindow : NSWindowController <NSComboBoxDataSource>
{
	NSArray			*roiNames;
	
}
/** Set Name and closes Window */
- (IBAction)setDefaultName:(id)sender;

/** Set default name to nil */
- (IBAction)unsetDefaultName:(id)sender;

/** Default initializer */
- (id)initWithController: (ViewerController*) c;

@end
