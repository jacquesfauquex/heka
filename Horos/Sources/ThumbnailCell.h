
#import <Cocoa/Cocoa.h>


@interface ThumbnailCell : NSButtonCell {
	BOOL rightClick;
    BOOL invertedSet, invertedColors;
}

@property(readonly) BOOL rightClick;

+ (float) thumbnailCellWidth;

@end
