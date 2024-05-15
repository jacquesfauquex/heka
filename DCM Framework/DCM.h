
#import "DCMValueRepresentation.h"
#import "DCMAttributeTag.h"
#import "DCMAttribute.h"
#import "DCMSequenceAttribute.h"
#import "DCMDataContainer.h"
#import "DCMObject.h"
#import "DCMTransferSyntax.h"
#import "DCMTagDictionary.h"
#import "DCMTagForNameDictionary.h"
#import "DCMCharacterSet.h"
#import "DCMPixelDataAttribute.h"
#import "DCMCalendarDate.h"

#import "DCMLimitedObject.h"

#import "DCMNetServiceDelegate.h"
#import "DCMEncapsulatedPDF.h"


#define DCMDEBUG 0
#define DCMFramework_compile YES


#import <Accelerate/Accelerate.h>

enum DCM_CompressionQuality {DCMLosslessQuality = 0, DCMHighQuality, DCMMediumQuality, DCMLowQuality};



@protocol MoveStatusProtocol
	- (void)setStatus:(unsigned short)moveStatus  numberSent:(int)numberSent numberError:(int)numberErrors;
@end


