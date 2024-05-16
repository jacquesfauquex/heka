
#import <Cocoa/Cocoa.h>
@class N2View;

__deprecated
@interface N2Panel : NSPanel {
	BOOL _canBecomeKeyWindow;
}

@property BOOL canBecomeKeyWindow;

@end
