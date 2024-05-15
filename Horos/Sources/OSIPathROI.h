#import <Cocoa/Cocoa.h>
#import "OSIROI.h"

@class ROI;
@class N3MutableBezierPath;

// for now implement closed poly first

@interface OSIPathROI : OSIROI {
	ROI *_osiriXROI;
	
	N3MutableBezierPath *_bezierPath;
}

- (id)initWithOsiriXROI:(ROI *)roi pixToDICOMTransfrom:(N3AffineTransform)pixToDICOMTransfrom;

@end
