#import "HotKeyTableView.h"
#import "OSIHotKeysPref.h"

@implementation HotKeyTableView

- (void) keyDown:(NSEvent *)theEvent
{
    if( [[theEvent characters] length] == 0) return;
    
	unichar		c = [[theEvent characters] characterAtIndex:0];
	
	if (c == NSUpArrowFunctionKey || c == NSDownArrowFunctionKey || c == NSLeftArrowFunctionKey || c == NSRightArrowFunctionKey || c == NSEnterCharacter || c == NSCarriageReturnCharacter || c == 27)
		return [super keyDown: theEvent];
	else
		[[OSIHotKeysPref currentKeysPref] keyDown: theEvent];
}

@end
