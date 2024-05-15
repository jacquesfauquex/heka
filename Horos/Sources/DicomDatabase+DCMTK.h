
#import "DicomDatabase.h"


@interface DicomDatabase (DCMTK)

+(BOOL)fileNeedsDecompression:(NSString*)path;
+(BOOL)compressDicomFilesAtPaths:(NSArray*)paths;
+(BOOL)compressDicomFilesAtPaths:(NSArray*)paths intoDirAtPath:(NSString*)destDir;
+(BOOL)decompressDicomFilesAtPaths:(NSArray*)paths;
+(BOOL)decompressDicomFilesAtPaths:(NSArray*)paths intoDirAtPath:(NSString*)destDir;
+(NSString*)extractReportSR:(NSString*)dicomSR contentDate:(NSDate*)date;
+(BOOL)testFiles:(NSArray*)files;

@end
