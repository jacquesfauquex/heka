
#import <Cocoa/Cocoa.h>
#import "VRView.h"
#import "SelectionView.h"

@interface VRPresetPreview : VRView {
	BOOL isEmpty, isSelected;
	IBOutlet SelectionView	*selectionView;
	
	IBOutlet VRController	*presetController;
	int presetIndex;
	BOOL _noNeedsDisplay;
}

- (void)setIsEmpty:(BOOL)empty;
- (BOOL)isEmpty;
- (void)setSelected;
- (void)setIndex:(int)index;
- (int)index;

@end
