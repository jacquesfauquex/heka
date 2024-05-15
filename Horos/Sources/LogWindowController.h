

#import <Cocoa/Cocoa.h>

/** \brief  Window Controller for network logs */
@interface LogWindowController : NSWindowController
{
	IBOutlet NSArrayController *receive, *move, *send, *web;
}

- (IBAction) export:(id) sender;

@end
