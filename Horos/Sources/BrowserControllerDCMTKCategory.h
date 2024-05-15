
#import <Cocoa/Cocoa.h>
#import "BrowserController.h"

/** \brief  Category for DCMTK calls from BrowserController */

@interface BrowserController (BrowserControllerDCMTKCategory)
+ (NSString*) compressionString: (NSString*) string;

- (NSData*) getDICOMFile:(NSString*) file inSyntax:(NSString*) syntax quality: (int) quality;
- (BOOL) testFiles: (NSArray*) files __deprecated;
- (BOOL) needToCompressFile: (NSString*) path __deprecated;
- (BOOL) compressDICOMWithJPEG:(NSArray *) paths __deprecated;
- (BOOL) compressDICOMWithJPEG:(NSArray *) paths to:(NSString*) dest __deprecated;
- (BOOL) decompressDICOMList:(NSArray *) files to:(NSString*) dest __deprecated;

@end
