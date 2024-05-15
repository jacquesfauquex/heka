#import <Foundation/Foundation.h>


@interface ThreadsManager : NSObject {
	@private 
	NSArrayController* _threadsController;
    NSTimer* _timer;
}

@property(readonly) NSArrayController* threadsController;

+(ThreadsManager*)defaultManager;

-(NSArray*)threads;
-(NSUInteger)threadsCount;
-(NSThread*)threadAtIndex:(NSUInteger)index;
-(void)addThreadAndStart:(NSThread*)thread;
-(void)removeThread:(NSThread*)thread;

@end
