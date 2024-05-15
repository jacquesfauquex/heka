
#import "DicomDatabase.h"


@interface DicomDatabase (Clean)

-(void)initClean;
-(void)deallocClean;

-(void)initiateCleanUnlessAlreadyCleaning;

-(void)cleanOldStuff;
-(void)cleanForFreeSpace;
-(void)cleanForFreeSpaceMB:(NSInteger)freeMemoryRequested; // so we can allow timed "deep clean"

@end
