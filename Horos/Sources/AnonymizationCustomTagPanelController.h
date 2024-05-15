#import <Cocoa/Cocoa.h>

@class DCMAttributeTag;

@interface AnonymizationCustomTagPanelController : NSWindowController {
	IBOutlet NSTextField* groupField;
	IBOutlet NSTextField* elementField;
}

-(IBAction)cancelButtonAction:(id)sender;
-(IBAction)okButtonAction:(id)sender;

@property(assign) DCMAttributeTag* attributeTag;

@end
