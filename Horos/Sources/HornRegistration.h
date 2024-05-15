

#import <Cocoa/Cocoa.h>

/** \brief VTK horn registration */


@interface HornRegistration : NSObject {
	NSMutableArray	*modelPoints, *sensorPoints;
	double *adRot, *adTrans;
}

- (void) addModelPointX: (double) x Y: (double) y Z: (double) z;
- (void) addSensorPointX: (double) x Y: (double) y Z: (double) z;
- (void) addModelPoint: (double*) point;
- (void) addSensorPoint: (double*) point;
- (short) numberOfPoint;
- (void) computeVTK:(double*) matrixResult;

- (double*) rotation;
- (double*) translation;

@end
