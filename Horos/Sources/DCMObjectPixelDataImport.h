
#import <Cocoa/Cocoa.h>
#import "DCMObject.h"


@interface DCMObjectPixelDataImport : DCMObject {

}

+ (id)objectWithContentsOfFile:(NSString *)file decodingPixelData:(BOOL)decodePixelData	;

@end
