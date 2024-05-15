#import <Cocoa/Cocoa.h>
#import "OSIEnvironment.h"

@class ViewerController;
@class DCMView;

@interface OSIEnvironment (Private)

- (void)addViewerController:(ViewerController *)viewerController;
- (void)removeViewerController:(ViewerController *)viewerController;

- (void)viewerControllerWillChangeData:(ViewerController *)viewerController;
- (void)viewerControllerDidChangeData:(ViewerController *)viewerController;

- (void)drawDCMView:(DCMView *)dcmView;

@end
