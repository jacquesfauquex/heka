#import <Cocoa/Cocoa.h>

@class SendController;

/** \brief Window Controller for the Wait Panel */
@interface Wait : NSWindowController <NSWindowDelegate>
{
    IBOutlet NSProgressIndicator *progress;
	IBOutlet NSTextField		 *text, *elapsed;
	IBOutlet NSButton			 *abort;
	
	SendController * _target;
	NSDate  *startTime;
	BOOL	cancel, aborted, openSession;
	NSModalSession session;
	NSTimeInterval lastTimeFrame, lastTimeFrameUpdate, firstTime, displayedTime;
}

- (void)incrementBy:(double)delta;
- (NSProgressIndicator*) progress;
- (id) initWithString:(NSString*) str;
- (id) initWithString:(NSString*) str :(BOOL) useSession;
- (BOOL) aborted;
- (IBAction) abortButton: (id) sender;
- (void) setCancel :(BOOL) val;
- (void) setElapsedString :(NSString*) str;
@end
