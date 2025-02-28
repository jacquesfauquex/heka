#import "PrettyCell.h"
#import "NSString+N2.h"
#import "N2Operators.h"
#import "N2Debug.h"
@interface PrettyCell ()

@property(readwrite,retain) NSMutableArray* rightSubviews;

@end

@implementation PrettyCell

@synthesize rightText = _rightText;
@synthesize rightSubviews = _rightSubviews;
@synthesize textColor = _textColor;

-(id)init {
    if ((self = [super init])) {
        self.rightSubviews = [NSMutableArray array];
        
        [self setImagePosition:NSImageLeft];
        [self setAlignment:NSLeftTextAlignment];
        [self setImageScaling: NSImageScaleProportionallyUpOrDown];
        [self setHighlightsBy:NSNoCellMask];
        [self setShowsStateBy:NSNoCellMask];
        [self setBordered:NO];
        [self setLineBreakMode:NSLineBreakByTruncatingMiddle];
        [self setButtonType:NSMomentaryChangeButton];
    }
    
    return self;
}

-(void)dealloc {
    self.rightText = nil;
    self.textColor = nil;
    self.rightSubviews = nil;
    [super dealloc];
}

-(id)copyWithZone:(NSZone *)zone {
    PrettyCell* copy = [super copyWithZone:zone];
    
    copy->_rightText = [self.rightText copyWithZone:zone];
    copy->_textColor = [self.textColor copyWithZone:zone];
    copy->_rightSubviews = [self.rightSubviews mutableCopyWithZone:zone];
    
    return copy;
}

-(NSRect)rectForSubviewAtIndex:(NSInteger)index withFrame:(NSRect)frame {
    NSInteger previousSummedupWidth = 0;
    for (int i = 0; i < index; ++i) {
        NSView* subview = [self.rightSubviews objectAtIndex:i];
        previousSummedupWidth += subview.frame.size.width;
    }
    
    NSView* subview = [self.rightSubviews objectAtIndex:index];
    NSRect subviewFrame = subview.frame;
    
    return NSMakeRect(NSMakePoint(frame.origin.x+frame.size.width-previousSummedupWidth-subviewFrame.size.width, frame.origin.y+(frame.size.height-subviewFrame.size.height)/2), subviewFrame.size);
}

-(NSRect)rectForSubview:(NSView*)subview withFrame:(NSRect)frame {
    return [self rectForSubviewAtIndex:[self.rightSubviews indexOfObject:subview] withFrame:frame];
}

- (void)drawImage:(NSImage *)image withFrame:(NSRect)frame inView:(NSView *)controlView {
    frame.origin.x += 1;
    [super drawImage:image withFrame:frame inView:controlView];
}

- (void)drawWithFrame:(NSRect)frame inView:(NSView *)controlView {
    NSRect initialFrame = frame;

    for (NSView* subview in self.rightSubviews) {
        NSRect subviewFrame = [self rectForSubview:subview withFrame:initialFrame];
        
        [subview setFrame:subviewFrame];
        if (![subview superview])
            [controlView addSubview:subview];
        
        if (subviewFrame.origin.x < frame.origin.x+frame.size.width)
            frame.size.width = subviewFrame.origin.x-frame.origin.x;
    }
    
    [super drawWithFrame:frame inView:controlView];
}

- (NSRect)drawTitle:(NSAttributedString*)title withFrame:(NSRect)frame inView:(NSView *)controlView {
    NSRect initialFrame = frame;
    static const CGFloat spacer = 2;

    NSMutableAttributedString* mutableTitle = [[title mutableCopy] autorelease];
    if (self.textColor) [mutableTitle addAttributes:[NSDictionary dictionaryWithObjectsAndKeys:self.textColor, NSForegroundColorAttributeName, nil] range:mutableTitle.range];
    title = mutableTitle;
    
    if (self.rightText.length && self.rightText.length < 100) {
        NSMutableDictionary* attributes = [[[self.attributedTitle attributesAtIndex:0 effectiveRange:NULL] mutableCopy] autorelease];
        NSMutableParagraphStyle* rightAlignmentParagraphStyle = [[[NSParagraphStyle defaultParagraphStyle] mutableCopy] autorelease];
        [rightAlignmentParagraphStyle setAlignment:NSRightTextAlignment];
        [attributes setObject:rightAlignmentParagraphStyle forKey:NSParagraphStyleAttributeName];

        frame.origin.y += 2;
        [self.rightText drawInRect:frame withAttributes:attributes];
        frame.origin.y -= 2;
        
        CGFloat w = [self.rightText sizeWithAttributes:attributes].width;
        frame.size.width -= w + spacer;
    }
    
    frame.origin.x += spacer;
    frame.size.width -= spacer;
	[super drawTitle:title withFrame:frame inView:controlView];
    
    return initialFrame;
}

- (BOOL)trackMouse:(NSEvent*)theEvent inRect:(NSRect)cellFrame ofView:(NSView *)controlView untilMouseUp:(BOOL)untilMouseUp {
    return NO;
}

-(void)setPlaceholderString:(NSString*)str {
    // this is a dummy function... AppKit calls this, and if we don't implement it, it fails
}

@end
