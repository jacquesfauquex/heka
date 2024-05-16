#import "N2Locker.h"

@implementation N2Locker

+ (id)lock:(id)lockedObject {
    return [[[self alloc] initWithLockedObject:lockedObject] autorelease];
}

- (id)initWithLockedObject:(id)lockedObject {
    if ((self = [super init])) {
        _lockedObject = [lockedObject retain];
        [_lockedObject lock];
    }
    
    return self;
}

- (void)dealloc {
    [_lockedObject unlock];
    [_lockedObject release];
    [super dealloc];
}

@end
