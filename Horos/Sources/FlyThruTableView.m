#import "FlyThruTableView.h"


#define FlyThruTableViewDataType @"FlyThruTableViewDataType"

@implementation FlyThruTableView

 //drag and drop delegates
 - (void)awakeFromNib
{
	NSLog(@"awake from nib");
    [self  registerForDraggedTypes:  [NSArray arrayWithObject:FlyThruTableViewDataType]];
	[self setVerticalMotionCanBeginDrag:YES];
 
}

- (BOOL)allowsColumnSelection
{
	return NO;
}

- (BOOL)canDragRowsWithIndexes:(NSIndexSet *)rowIndexes atPoint:(NSPoint)mouseDownPoint{
	return YES;
}



@end
