


#import <AppKit/AppKit.h>

@class ROI;

/** \brief  View for histogram display */

@interface HistoView : NSView
{
        float					*dataArray;
		long					dataSize, bin, curMousePosition, pixels, minV, maxV;
        float					maxValue;
		ROI						*curROI;
		NSColor					*backgroundColor, *binColor, *selectedBinColor, *textColor, *borderColor;
}
- (void)setData:(float*)array :(long) size :(long) b;
- (void)setMaxValue:(float)value :(long) pixels;
- (void)setCurROI: (ROI*) r;
- (void)setRange:(long) mi :(long) max;

- (NSColor*)backgroundColor;
- (NSColor*)binColor;
- (NSColor*)selectedBinColor;
- (NSColor*)textColor;
- (NSColor*)borderColor;

- (void)setBackgroundColor:(NSColor*)aColor;
- (void)setBinColor:(NSColor*)aColor;
- (void)setSelectedBinColor:(NSColor*)aColor;
- (void)setTextColor:(NSColor*)aColor;
- (void)setBorderColor:(NSColor*)aColor;

@end
