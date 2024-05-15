
#import <Cocoa/Cocoa.h>
#import "Camera.h"
#import "Window3DController.h"

/** \brief Adapter for FlyThru
*
*  Adaptor FlyThru
*  Subclassed for SR, VR, VRPro
*/

@interface FlyThruAdapter : NSObject {
	
	Window3DController	*controller;

}

- (id) initWithWindow3DController: (Window3DController*) aWindow3DController;
- (Camera*) getCurrentCamera;
- (void) setCurrentViewToCamera:(Camera*)aCamera;
- (NSImage*) getCurrentCameraImage:(BOOL) highQuality;
- (void) prepareMovieGenerating;
- (void) endMovieGenerating;
- (void) setCurrentViewToLowResolutionCamera:(Camera*)aCamera;

@end
