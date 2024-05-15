#import <Cocoa/Cocoa.h>

@interface O2ViewerThumbnailsMatrix : NSMatrix <NSDraggingSource> {
    BOOL avoidRecursive;
    NSPoint draggingStartingPoint;
    NSTimeInterval doubleClick;
    NSCell *doubleClickCell;
}

@end

@interface O2ViewerThumbnailsMatrixRepresentedObject : NSObject {
    id _object;
    NSArray* _children;
}

@property(retain) id object;
@property(retain) NSArray* children;

+ (id)object:(id)object;
+ (id)object:(id)object children:(NSArray*)children;

@end
