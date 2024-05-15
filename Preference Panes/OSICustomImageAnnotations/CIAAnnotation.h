#import <Cocoa/Cocoa.h>

@class CIAPlaceHolder;

@interface CIAAnnotation : NSView {
	BOOL isSelected;
	NSPoint mouseDownLocation;
	CIAPlaceHolder *placeHolder;
	NSColor *color, *backgroundColor;
	NSString *title;
	NSMutableArray *content;
	BOOL isOrientationWidget;
	NSPoint animatedFrameOrigin;
	float width;
}

+ (NSSize)defaultSize;

- (void)setIsSelected:(BOOL)boo;
- (CIAPlaceHolder*)placeHolder;
- (void)setPlaceHolder:(CIAPlaceHolder*)aPlaceHolder;
- (NSString*)title;
- (void)setTitle:(NSString*)aTitle;
- (NSMutableArray*)content;
- (void)setContent:(NSArray*)newContent;
- (int)countOfContent;
- (NSString*)objectInContentAtIndex:(unsigned)index;
- (void)getContent:(NSString **)strings range:(NSRange)inRange;
- (void)insertObject:(NSString *)string inContentAtIndex:(unsigned int)index;
- (void)removeObjectFromContentAtIndex:(unsigned int)index;

- (NSPoint)mouseDownLocation;
- (void)setMouseDownLocation:(NSPoint)newLocation;
- (void)recomputeMouseDownLocation;

- (BOOL)isOrientationWidget;
- (void)setIsOrientationWidget:(BOOL)boo;

- (float)width;

- (NSPoint)animatedFrameOrigin;
- (void)setAnimatedFrameOrigin:(NSPoint)newOrigin;

@end
