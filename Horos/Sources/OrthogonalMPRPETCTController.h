#import <Cocoa/Cocoa.h>
#import "OrthogonalMPRController.h"
#import "OrthogonalMPRPETCTView.h"

@class OrthogonalMPRPETCTViewer;

/** \brief OrthogonalMPRController for PET-CT */

@interface OrthogonalMPRPETCTController : OrthogonalMPRController {

	BOOL						isBlending;
}
- (id) initWithPixList: (NSMutableArray*) pix :(NSArray*) files :(NSData*) vData :(ViewerController*) vC :(ViewerController*) bC :(id) newViewer;

- (void) resliceFromOriginal: (float) x : (float) y;
- (void) resliceFromX: (float) x : (float) y;
- (void) resliceFromY: (float) x : (float) y;

- (void) superSetWLWW:(float) iwl :(float) iww;

- (void) setBlendingMode:(long) f;
-(void) setBlendingFactor:(float) f;
- (void) stopBlending;
- (void) scaleToFit;

- (BOOL) containsView: (DCMView*) view;

- (void) fullWindowModality: (id) sender;
- (void) fullWindowPlan: (id) sender;

-(void) ApplyOpacityString:(NSString*) str;

- (void) flipVertical:(id) sender : (OrthogonalMPRPETCTView*) view;
- (void) flipHorizontal:(id) sender : (OrthogonalMPRPETCTView*) view;
@end
