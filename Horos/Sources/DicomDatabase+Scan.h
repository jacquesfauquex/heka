

#import "DicomDatabase.h"


@interface DicomDatabase (Scan)

-(BOOL)scanAtPath:(NSString*)path;
+(NSString*)_findDicomdirIn:(NSArray*)allpaths;

@end
