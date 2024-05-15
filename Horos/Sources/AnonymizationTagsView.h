#import <Cocoa/Cocoa.h>


@class DCMAttributeTag, AnonymizationViewController, AnonymizationTagsPopUpButton, N2TextField;

@interface AnonymizationTagsView : NSView {
	NSMutableArray* viewGroups;
	NSSize intercellSpacing, cellSize;
	IBOutlet AnonymizationViewController* anonymizationViewController;
	AnonymizationTagsPopUpButton* dcmTagsPopUpButton;
	NSButton* dcmTagAddButton;
}

-(void)addTag:(DCMAttributeTag*)tag;
-(void)removeTag:(DCMAttributeTag*)tag;
-(NSSize)idealSize;

-(NSButton*)checkBoxForObject:(id)object;
-(N2TextField*)textFieldForObject:(id)object;

@end
