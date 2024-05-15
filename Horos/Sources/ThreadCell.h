#import <Foundation/Foundation.h>


@class ThreadsManager;

@interface ThreadCell : NSTextFieldCell {
	NSProgressIndicator* _progressIndicator;
	ThreadsManager* _manager;
	NSButton* _cancelButton;
	NSThread* _thread;
    id _retainedThreadDictionary;
	NSTableView* _view;

    CGFloat _lastDisplayedProgress;
    BOOL KVOObserving;
}

@property(retain) NSProgressIndicator* progressIndicator;
@property(retain) NSButton* cancelButton;
@property(nonatomic, retain) NSThread* thread;
@property(assign, readonly) ThreadsManager* manager;
@property(assign, readonly) NSTableView* view;

-(id)initWithThread:(NSThread*)thread manager:(ThreadsManager*)manager view:(NSTableView*)view;

-(void)cleanup;

-(NSRect)statusFrame;

@end
