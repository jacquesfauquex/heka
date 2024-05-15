#ifdef _STEREO_VISION_


#import <Cocoa/Cocoa.h>
#import "VRController.h"
#import "DCMPix.h"
#import "ColorTransferView.h"
#import "ViewerController.h"
#import "Window3DController.h"
#import "ShadingArrayController.h"

// Fly Thru
#import "FlyThruController.h"
#import "FlyThru.h"
#import "VRFlyThruAdapter.h"

// ROIs Volumes
#define roi3Dvolume

@class CLUTOpacityView;
@class VRView;
@class ROIVolume;

@class VRPresetPreview;
#import "ColorView.h"


@interface VRController (StereoVision)

- (IBAction) ApplyGeometrieSettings: (id) sender;


@end
#endif
