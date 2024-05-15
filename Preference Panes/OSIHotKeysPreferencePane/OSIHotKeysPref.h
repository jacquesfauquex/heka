#import <PreferencePanes/PreferencePanes.h>
#import "HotKeyArrayController.h"

@interface OSIHotKeysPref : NSPreferencePane 
{
	NSArray *_actions;
	IBOutlet NSTextFieldCell *keyTextFieldCell;
	IBOutlet HotKeyArrayController *arrayController;
    IBOutlet NSWindow *mainWindow;
    
    id _tlos;
}

+ (OSIHotKeysPref*) currentKeysPref;
- (void) keyDown:(NSEvent *)theEvent;
- (void) mainViewDidLoad;
- (NSArray *)actions;
- (void)setActions:(NSArray *)actions;

@end
