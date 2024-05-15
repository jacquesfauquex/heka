
#import <Cocoa/Cocoa.h>
#import "XMLController.h"

/** \brief DCMTK calls for xml */

@interface XMLController (XMLControllerDCMTKCategory)

+ (BOOL) modifyDicom:(NSArray*) tagAndValues dicomFiles:(NSArray*) dicomFiles;

+ (int) modifyDicom:(NSArray*) params encoding: (NSStringEncoding) encoding;

- (void) prepareDictionaryArray;

- (int) getGroupAndElementForName:(NSString*) name group:(int*) gp element:(int*) el;

@end
