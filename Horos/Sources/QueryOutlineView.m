#import "QueryOutlineView.h"


@implementation QueryOutlineView

- (void)keyDown:(NSEvent *)event
{
    if( [[event characters] length] == 0) return;
    
	unichar c = [[event characters] characterAtIndex:0];
	 
	if( c >= 0xF700 && c <= 0xF8FF) // Functions keys
		[super keyDown: event];
	else if( c == 9) // Tab Key
		[super keyDown: event];
	else
		[[[self window] windowController] keyDown: event];
}

- (BOOL)becomeFirstResponder
{
    if( [[NSUserDefaults standardUserDefaults] boolForKey: @"displaySamePatientWithColorBackground"])
        [self setNeedsDisplay: YES];
    
    return YES;
}

- (BOOL)resignFirstResponder
{
    if( [[NSUserDefaults standardUserDefaults] boolForKey: @"displaySamePatientWithColorBackground"])
        [self setNeedsDisplay: YES];
    
    return YES;
}
@end
