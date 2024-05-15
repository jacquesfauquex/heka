/** \brief Converts DICOM string  to NSString */

#import <Cocoa/Cocoa.h>

@interface NSString  (DICOMToNSString)

- (id) initWithCString:(const char *)cString  DICOMEncoding:(NSString *)encoding;
+ (id) stringWithUTF8String:(const char *)cString  DICOMEncoding:(NSString *)encoding;
+ (NSStringEncoding)encodingForDICOMCharacterSet:(NSString *)characterSet;


@end
