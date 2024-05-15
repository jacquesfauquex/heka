#import <Foundation/Foundation.h>
#import "DCMPixelDataAttribute.h"



@interface DCMPixelDataAttribute (DCMPixelDataAttributeJPEG16) 

- (NSData *)convertJPEG16ToHost:(NSData *)jpegData;

@end
