


#import "Piecewise3D.h"


@implementation Piecewise3D

- (id) init
{
	self = [super init];
	xPiecewise = vtkPiecewiseFunction::New();
	yPiecewise = vtkPiecewiseFunction::New();
	zPiecewise = vtkPiecewiseFunction::New();
	return self;
}

- (void) dealloc
{
	xPiecewise->Delete();
	yPiecewise->Delete();
	zPiecewise->Delete();
	
	[super dealloc];
}

- (void) addPoint: (float) t : (Point3D*) p
{
	float x, y, z;
	x = [p x];
	y = [p y];
	z = [p z];
	xPiecewise->AddPoint(t, x);
	yPiecewise->AddPoint(t, y);
	zPiecewise->AddPoint(t, z);
}

- (Point3D*) evaluateAt: (float) t
{
	float x, y, z;
	x = xPiecewise->GetValue(t);
	y = yPiecewise->GetValue(t);
	z = zPiecewise->GetValue(t);
	return [[[Point3D alloc] initWithValues:x :y :z] autorelease];
}

@end
