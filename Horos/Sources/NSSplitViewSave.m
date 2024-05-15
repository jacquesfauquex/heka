#import "NSSplitViewSave.h"

@implementation NSSplitView(Defaults)

- (void) restoreDefault: (NSString *) defaultName
{
    NSArray *frames = [[NSUserDefaults standardUserDefaults] arrayForKey: defaultName];
    
    if( frames.count == self.subviews.count)
    {
        int i = 0;
        
        for( NSView *v in [self subviews])
            [v setFrame: NSRectFromString( [frames objectAtIndex: i++])];
    }
    
    [self adjustSubviews];
}

- (void) saveDefault: (NSString *) defaultName
{
    NSMutableArray *frameArray = [NSMutableArray array];
    
    for( NSView *v in [self subviews])
    {
        if( [self isSubviewCollapsed: v])
        {
            NSRect frame = v.frame;
            
            if( [self isVertical])
                frame.size.width = 0;
            else
                frame.size.height = 0;
            
            [frameArray addObject: NSStringFromRect( v.frame)];
        }
        else
            [frameArray addObject: NSStringFromRect( v.frame)];
    }
    [[NSUserDefaults standardUserDefaults] setObject: frameArray forKey: defaultName];
}

@end
