
#import <AppKit/AppKit.h>

@interface PrettyCell : NSButtonCell {
    NSString* _rightText;
    NSMutableArray* _rightSubviews;
    NSColor* _textColor;
}

@property(retain) NSString* rightText;
@property(readonly,retain) NSMutableArray* rightSubviews;
@property(retain) NSColor* textColor;

@end
