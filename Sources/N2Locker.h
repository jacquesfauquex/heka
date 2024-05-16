#import <Foundation/Foundation.h>

@interface N2Locker : NSObject {
    id _lockedObject;
}

+ (id)lock:(id)lockedObject;

@end
