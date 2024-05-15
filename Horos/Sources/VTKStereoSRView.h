#ifdef _STEREO_VISION_

#import <Cocoa/Cocoa.h>
#import <AppKit/AppKit.h>

#ifdef __cplusplus
#import "vtkCocoaGLView.h"
#import "VTKView.h"

//#import "vtkCocoaWindow.h"
//#define id Id
#include "vtkCamera.h"
#include "vtkRenderer.h"
#include "vtkRenderWindow.h"
#include "vtkRenderWindowInteractor.h"
#include "vtkCocoaRenderWindowInteractor.h"
#include "vtkCocoaRenderWindow.h"

//#undef id
#else
typedef char* vtkCocoaWindow;
typedef char* vtkRenderer;
typedef char* vtkRenderWindow;
typedef char* vtkRenderWindowInteractor;
typedef char* vtkCocoaRenderWindowInteractor;
typedef char* vtkCocoaRenderWindow;
typedef char* vtkCamera;
#endif

@class SRView;

@interface VTKStereoSRView : VTKView {
	
	NSCursor					*cursor;
	
	SRView	*superSRView;

}

-(id)initWithFrame:(NSRect)frame: (SRView*) aSRView;

@end
#endif
