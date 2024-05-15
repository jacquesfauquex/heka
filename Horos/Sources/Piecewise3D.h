
#import <Cocoa/Cocoa.h>
#import "Interpolation3D.h"

#ifdef __cplusplus
#include <vtkPiecewiseFunction.h>
#else
typedef char* vtkPiecewiseFunction;
#endif


/** \brief Linear interpolation for FlyThru
*/


@interface Piecewise3D : Interpolation3D {
	vtkPiecewiseFunction	*xPiecewise, *yPiecewise, *zPiecewise;
}

@end
