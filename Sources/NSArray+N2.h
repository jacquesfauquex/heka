#import <Cocoa/Cocoa.h>


@interface NSArray (N2)

- (NSArray*)splitArrayIntoArraysOfMinSize:(NSUInteger)chunkSize maxArrays:(NSUInteger)maxArrays;
- (NSArray*)splitArrayIntoChunksOfMinSize:(NSUInteger)chunkSize maxChunks:(NSUInteger)maxChunks;
- (id) deepMutableCopy;

@end


@interface NSMutableArray (N2)

-(void)addUniqueObjectsFromArray:(NSArray*)array;

@end
