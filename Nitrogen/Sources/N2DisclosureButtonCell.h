#import <Cocoa/Cocoa.h>

@interface N2DisclosureButtonCell : NSButtonCell {
	NSMutableDictionary* _attributes;
}

@property(readonly) NSMutableDictionary* attributes;

-(NSSize)textSize;

@end
