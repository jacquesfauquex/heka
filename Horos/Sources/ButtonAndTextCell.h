

#import <Cocoa/Cocoa.h>

/** \brief Cell for a ButtonAndTextField */
@interface ButtonAndTextCell : NSTextFieldCell {
	NSButtonCell *buttonCell;
	NSTextFieldCell *textCell;
}

-(IBAction) peformAction:(id)sender;

@end
