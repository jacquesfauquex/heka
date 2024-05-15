#import <Cocoa/Cocoa.h>
#import "OSIROI.h"

@class OSIFloatVolumeData;

@interface OSICoalescedPlanarROI : OSIROI {
    NSArray *_sourceROIs;
    
    OSIFloatVolumeData *_coalescedROIMaskVolumeData;
    
    OSISlab _cachedSlab;
    N3AffineTransform _cachedDicomToPixTransform;
    N3Vector _cachedMinCorner;
    NSData *_cachedMaskRunsData;
}

- (id)initWithSourceROIs:(NSArray *)rois homeFloatVolumeData:(OSIFloatVolumeData *)floatVolumeData;

@property (readonly, copy) NSArray *sourceROIs;

@end
