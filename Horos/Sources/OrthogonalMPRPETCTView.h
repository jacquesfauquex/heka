#import <Cocoa/Cocoa.h>
#import "OrthogonalMPRView.h"

/** \brief OrthogonalMPRView for PET-CT fusion */

@interface OrthogonalMPRPETCTView : OrthogonalMPRView {
}
- (void) superSetBlendingFactor:(float) f;
- (void) superFlipVertical:(id) sender;
- (void) superFlipHorizontal:(id) sender;

@end
