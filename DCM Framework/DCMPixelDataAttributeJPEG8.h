#import <Foundation/Foundation.h>
#import "DCMPixelDataAttribute.h"

 
@interface DCMPixelDataAttribute (DCMPixelDataAttributeJPEG8)

- (NSMutableData *)convertJPEG8LosslessToHost:(NSData *)jpegData;
- (NSMutableData *)compressJPEG8:(NSMutableData *)data  compressionSyntax:(DCMTransferSyntax *)compressionSyntax quality:(float)quality;


@end
