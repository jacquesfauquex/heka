#import <Cocoa/Cocoa.h>

@class FlyThruController;


/** \brief  Manages the array of FlyThru steps
*
* A subclass of NSArrayController used to manage the steps of the flythru.
* Each step consists of a Camera -- See Camera.h
* Uses the usual NSArrayController methods.
*/


@interface FlyThruStepsArrayController : NSArrayController {
	IBOutlet FlyThruController *flyThruController;
	IBOutlet NSTableView	*tableview;
}

- (IBAction) flyThruButton:(id) sender;
- (void) flyThruTag:(int) x;
- (void) resetCameraIndexes;
- (IBAction)updateCamera:(id)sender;
- (IBAction)resetCameras:(id)sender;
- (void) keyDown:(NSEvent *)theEvent;

@end
