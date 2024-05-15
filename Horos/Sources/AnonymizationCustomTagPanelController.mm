
#import "AnonymizationCustomTagPanelController.h"
#import "DCMAttributeTag.h"


@implementation AnonymizationCustomTagPanelController

-(id)init
{
	self = [super initWithWindowNibName:@"AnonymizationCustomTagPanel"];
	[self window]; // load
	return self;
}

-(IBAction)cancelButtonAction:(id)sender
{
	[NSApp endSheet:self.window returnCode:NSRunAbortedResponse];
}

-(IBAction)okButtonAction:(id)sender
{
	[NSApp endSheet:self.window];
}

-(DCMAttributeTag*)attributeTag
{
	return [DCMAttributeTag tagWithGroup:[[groupField objectValue] unsignedIntValue] element:[[elementField objectValue] unsignedIntValue]];
}

-(void)setAttributeTag:(DCMAttributeTag*)tag
{
	[groupField setObjectValue:[NSNumber numberWithUnsignedInt:tag.group]];
	[elementField setObjectValue:[NSNumber numberWithUnsignedInt:tag.element]];
}

@end
