#import <Foundation/Foundation.h>
#import "DCMPixelDataAttribute.h"



@interface DCMPixelDataAttribute (DCMPixelDataAttributeJPEG12)  

- (NSData *)convertJPEG12ToHost:(NSData *)jpegData;
//- (NSMutableData *)compressJPEG12:(NSMutableData *)data  compressionSyntax:(DCMTransferSyntax *)compressionSyntax  quality:(float)quality;

@end
