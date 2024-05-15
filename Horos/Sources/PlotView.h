


#import <AppKit/AppKit.h>

@class ROI;

/** \brief  Plot View */

@interface PlotView : NSView
{
			float					*dataArray;
			long					dataSize;
			long					curMousePosition;
			ROI						*curROI;
}
- (void)setData:(float*)array :(long) size;
- (void)setCurROI: (ROI*) r;
@end
