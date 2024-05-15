#import <Cocoa/Cocoa.h>
#import "DCMObject.h"

/** Category of DCMObject for creating DICOM encapsulated PDFs */
@interface   DCMObject (DCMEncapsulatedPDF) 


/** Encapsulates a pdf in a DICOM file */
+ (DCMObject*) encapsulatedPDF:(NSData *)pdf;


@end
