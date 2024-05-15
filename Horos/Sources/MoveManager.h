
#import <Cocoa/Cocoa.h>

/** \brief move manager */
@interface MoveManager : NSObject {
	NSMutableSet *_set;
}

+ (id)sharedManager;
- (void)addMove:(id)move;
- (void)removeMove:(id)move;
- (BOOL)containsMove:(id)move;

@end
