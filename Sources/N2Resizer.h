#import <Cocoa/Cocoa.h>


@interface N2Resizer : NSObject {
	NSView* _observed;
	NSView* _affected;
	BOOL _resizing;
}

@property(retain) NSView* observed;
@property(retain) NSView* affected;

-(id)initByObservingView:(NSView*)observed affecting:(NSView*)affected;

@end
