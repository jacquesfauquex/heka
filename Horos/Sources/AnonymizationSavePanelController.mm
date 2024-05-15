#import "AnonymizationSavePanelController.h"
#import "AnonymizationViewController.h"
#import "NSFileManager+N2.h"


@implementation AnonymizationSavePanelController

@synthesize outputDir;

-(id)initWithTags:(NSArray*)shownDcmTags values:(NSArray*)values {
	return [self initWithTags:shownDcmTags values:values nibName:@"AnonymizationSavePanel"];
}

-(void)dealloc {
	NSLog(@"AnonymizationSavePanelController dealloc");
	self.outputDir = NULL;
	[super dealloc];
}

#pragma mark Save Panel

-(IBAction)actionOk:(NSView*)sender {
	end = AnonymizationPanelOk;
	NSOpenPanel* panel = [NSOpenPanel openPanel];
	panel.canChooseFiles = NO;
	panel.canChooseDirectories = YES;
	panel.canCreateDirectories = YES;
	panel.allowsMultipleSelection = NO;
	panel.accessoryView = NULL;
	panel.message = NSLocalizedString(@"Select the location where to export the DICOM files:", NULL);
	panel.prompt = NSLocalizedString(@"Choose", NULL);
	// TODO: save and reuse location
    [panel beginSheetModalForWindow:self.window completionHandler:^(NSModalResponse returnCode) {
        if (returnCode != NSFileHandlingPanelOKButton)
            return;
        
        self.outputDir = [panel.URL path];
        
        [NSApp endSheet:self.window];
    }];
}

-(IBAction)actionAdd:(NSView*)sender {
	end = AnonymizationSavePanelAdd;
	[NSApp endSheet:self.window];
}

-(IBAction)actionReplace:(NSView*)sender {
	end = AnonymizationSavePanelReplace;
	[NSApp endSheet:self.window];
}

@end
