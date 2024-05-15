#import <Cocoa/Cocoa.h>

@class CIAAnnotation;

typedef enum {CIAPlaceHolderAlignLeft, CIAPlaceHolderAlignCenter, CIAPlaceHolderAlignRight} CIAPlaceHolderAlignement;
typedef enum {CIAPlaceHolderOrientationWidgetTop, CIAPlaceHolderOrientationWidgetBottom} CIAPlaceHolderOrientationWidgetPosition;

@interface CIAPlaceHolder : NSView  {
	BOOL hasFocus;
	NSMutableArray *annotationsArray;
	NSSize animatedFrameSize;
	CIAPlaceHolderAlignement align;
	CIAPlaceHolderOrientationWidgetPosition orientationWidgetPosition;
}

+ (NSSize)defaultSize;
- (BOOL)hasFocus;
- (void)setHasFocus:(BOOL)boo;
- (BOOL)hasAnnotations;
- (void)removeAnnotation:(CIAAnnotation*)anAnnotation;
- (void)insertAnnotation:(CIAAnnotation*)anAnnotation atIndex:(int)index animate:(BOOL)animate;
- (void)insertAnnotation:(CIAAnnotation*)anAnnotation atIndex:(int)index;
- (void)addAnnotation:(CIAAnnotation*)anAnnotation animate:(BOOL)animate;
- (void)addAnnotation:(CIAAnnotation*)anAnnotation;
- (BOOL)containsAnnotation:(CIAAnnotation*)anAnnotation;
- (NSMutableArray*)annotationsArray;
- (void)alignAnnotations;
- (void)alignAnnotationsWithAnimation:(BOOL)animate;
- (void)updateFrameAroundAnnotations;
- (void)updateFrameAroundAnnotationsWithAnimation:(BOOL)animate;
- (void)setAnimatedFrameSize:(NSSize)size;
- (void)setAlignment:(CIAPlaceHolderAlignement)alignement;
- (void)setOrientationWidgetPosition:(CIAPlaceHolderOrientationWidgetPosition)pos;

@end
