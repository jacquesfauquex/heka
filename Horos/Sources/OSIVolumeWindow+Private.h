#import <Cocoa/Cocoa.h>
#import "OSIVolumeWindow.h"

@class ViewerController;
@class DCMView;

@interface OSIVolumeWindow (Private)

- (id)initWithViewerController:(ViewerController *)viewerController;
- (void)viewerControllerDidClose;
- (void)viewerControllerWillChangeData;
- (void)viewerControllerDidChangeData;

- (void)drawInDCMView:(DCMView *)dcmView;
- (void)setNeedsDisplay;

@end




