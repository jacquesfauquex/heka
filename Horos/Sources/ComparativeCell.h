
#import <AppKit/AppKit.h>

@interface ComparativeCell : NSButtonCell
{
    NSString *_rightTextFirstLine, *_rightTextSecondLine, *_leftTextSecondLine, *_leftTextFirstLine;
    NSColor *_textColor;
}

@property(retain) NSString *rightTextFirstLine, *rightTextSecondLine, *leftTextSecondLine, *leftTextFirstLine;
@property(retain) NSColor *textColor;

@end
