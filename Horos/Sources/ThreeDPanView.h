#import <Cocoa/Cocoa.h>
#import "ThreeDPositionController.h"

@interface ThreeDPanView : NSImageView
{
	NSPoint mouseDownPoint;
	ThreeDPositionController *controller;
}

- (void)setController: (ThreeDPositionController*) c;

@end
