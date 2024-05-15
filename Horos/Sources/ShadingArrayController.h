#import <Cocoa/Cocoa.h>
#import "OSIWindowController.h"

@interface ShadingArrayController : NSArrayController {
	BOOL				_enableEditing;
//    OSIWindowController    *winController;
}

- (BOOL)enableEditing;
- (void)setEnableEditing:(BOOL)enable;
//- (void)setWindowController:(OSIWindowController*) ctrl;

@end
