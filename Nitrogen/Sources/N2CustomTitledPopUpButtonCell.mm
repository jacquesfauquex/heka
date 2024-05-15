
#import "N2CustomTitledPopUpButtonCell.h"


@implementation N2CustomTitledPopUpButtonCell

@synthesize displayedTitle;

-(void)dealloc {
	self.displayedTitle = NULL;
	[super dealloc];
}

-(NSRect)drawTitle:(NSAttributedString*)title withFrame:(NSRect)frame inView:(NSView*)controlView {
	NSString* t = displayedTitle? displayedTitle : @"";
	
	[t drawInRect:frame withAttributes:[title attributesAtIndex:0 effectiveRange:NULL]];
	
	return frame;
}

- (id) copyWithZone:(NSZone *)zone
{
    N2CustomTitledPopUpButtonCell* copy = [[N2CustomTitledPopUpButtonCell allocWithZone:zone] init];
	if (copy == nil) return nil;
	
	copy->displayedTitle = [self.displayedTitle copyWithZone: zone];
    
    return copy;
}

@end
