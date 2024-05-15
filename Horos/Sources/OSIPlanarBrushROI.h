#import "OSIROI.h"
#import "OSIGeometry.h"

@class OSIVolumeData;
@class ROI;

@interface OSIPlanarBrushROI : OSIROI
{
    ROI *_osiriXROI;
    
    OSIFloatVolumeData *_brushMask;
    N3Plane _plane;
    NSArray *_convexHull;
}
@end
