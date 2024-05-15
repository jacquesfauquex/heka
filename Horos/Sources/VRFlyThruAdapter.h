
#import <Cocoa/Cocoa.h>
#import "FlyThruAdapter.h"

@class VRController;

/** \brief FlyThruAdapter for Volume Rendering
*
* Volume Rendering FlyThruAdapter
*/

@interface VRFlyThruAdapter : FlyThruAdapter {
}

- (id) initWithVRController: (VRController*) aVRController;
- (NSImage*) getCurrentCameraImage: (BOOL) highQuality;

@end
