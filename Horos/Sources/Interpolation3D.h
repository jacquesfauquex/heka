
#import <Cocoa/Cocoa.h>
#import "Point3D.h"

/** \brief Interpolates flight path between FlyThru steps
*/

@interface Interpolation3D : NSObject {
}

- (void) addPoint: (float) t : (Point3D*) p;
- (Point3D*) evaluateAt: (float) t;

@end
