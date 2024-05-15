#import "HotKeyTextFieldCell.h"
#import "HotKeyFormatter.h"


@implementation HotKeyTextFieldCell


- (void)awakeFromNib{
	HotKeyFormatter *formatter = [[[HotKeyFormatter alloc] init] autorelease];
	[self setFormatter:formatter];
}


@end
