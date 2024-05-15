

#import <Cocoa/Cocoa.h>

/** \brief Control with a button and textField */
@interface ButtonAndTextField : NSTextField {
	IBOutlet NSTextField *textField;
	IBOutlet NSButton *button;
}

@end
