
#import <Cocoa/Cocoa.h>
#import "DicomImage.h"

/** \brief  DCMTK calls for Dicom Image */ 
@interface DicomImage (DicomImageDCMTKCategory)

- (NSString *)keyObjectType;
- (NSArray *)referencedObjects;
@end
