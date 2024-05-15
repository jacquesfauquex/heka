#import <Cocoa/Cocoa.h>


@interface N2ImageButtonCell : NSButtonCell {
	NSImage* altImage;
}

@property(retain) NSImage* altImage;

-(id)initWithImage:(NSImage*)image altImage:(NSImage*)altImage;

@end
