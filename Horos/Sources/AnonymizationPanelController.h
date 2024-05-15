#import <Cocoa/Cocoa.h>


enum AnonymizationPanelEnds {
	AnonymizationPanelCancel = 0,
	AnonymizationPanelOk
};

@class AnonymizationViewController;

@interface AnonymizationPanelController : NSWindowController {
	IBOutlet NSView* containerView;
	AnonymizationViewController* anonymizationViewController;
	int end;
	id representedObject;
}

@property(readonly) NSView* containerView;
@property(retain,readonly) AnonymizationViewController* anonymizationViewController;
@property(readonly) int end;
@property(retain) id representedObject;

-(id)initWithTags:(NSArray*)shownDcmTags values:(NSArray*)values;
-(id)initWithTags:(NSArray*)shownDcmTags values:(NSArray*)values nibName:(NSString*)nibName;

-(IBAction)actionOk:(NSView*)sender;
-(IBAction)actionCancel:(NSView*)sender;

@end
