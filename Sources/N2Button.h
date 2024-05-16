#import <Cocoa/Cocoa.h>


@interface N2Button : NSButton {
	id _representedObject;
}

@property(retain) id representedObject;

@end
