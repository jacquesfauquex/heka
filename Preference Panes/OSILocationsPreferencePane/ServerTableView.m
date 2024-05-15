#import "ServerTableView.h"
#import "DNDArrayController.h"
#import "OSILocationsPreferencePanePref.h"

@implementation ServerTableView
- (NSDragOperation)draggingSourceOperationMaskForLocal:(BOOL)flag
{
	if( !flag)
	{
		// link for external dragged URLs
		return NSDragOperationLink;
	}
	return [super draggingSourceOperationMaskForLocal:flag];
}

- (void) keyDown: (NSEvent *) event
{
    if( [[event characters] length] == 0) return;
    
	unichar c = [[event characters] characterAtIndex:0];
	
	if (( c == NSDeleteFunctionKey || c == NSDeleteCharacter || c == NSBackspaceCharacter || c == NSDeleteCharFunctionKey) && [self selectedRow] >= 0 && [self numberOfRows] > 0)
	{
		[(DNDArrayController*)[self delegate] deleteSelectedRow:self];
	}
	else
		[super keyDown:event];
}

@end
