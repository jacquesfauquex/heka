#import <Cocoa/Cocoa.h>

@interface CIALayoutView : NSControl {
	NSArray *placeHolderArray;
	NSString *disabledText;
	NSString *enabledText;
}

- (void)updatePlaceHolderOrigins;
- (void)updatePlaceHolderOriginsInRect:(NSRect)rect;
- (NSArray*)placeHolderArray;
- (void)setDisabledText:(NSString*)text;
- (void)setDefaultDisabledText;
- (void)setDefaultEnabledText;
@end
