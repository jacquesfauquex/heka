#import <Cocoa/Cocoa.h>


@interface N2TextField : NSTextField {
//	NSColor* invalidContentBackgroundColor;
	BOOL formatIsOk;
}

//@property(retain) NSColor* invalidContentBackgroundColor;
@property(nonatomic, readonly) BOOL formatIsOk;

@end
