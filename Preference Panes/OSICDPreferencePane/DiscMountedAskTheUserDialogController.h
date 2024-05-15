#import <Cocoa/Cocoa.h>

@interface DiscMountedAskTheUserDialogController : NSWindowController {
    NSString* _mountedPath;
    NSInteger _filesCount;
    NSInteger _choice;
    // Outlets
    NSTextField* _label;
}

@property(assign) IBOutlet NSTextField* label;
@property(readonly) NSInteger choice;

-(id)initWithMountedPath:(NSString*)path dicomFilesCount:(NSInteger)count;

-(IBAction)buttonAction:(NSButton*)sender;

@end
