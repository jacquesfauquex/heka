

#import <Cocoa/Cocoa.h>
#import "DCMObject.h"

@interface DCMObjectDBImport : DCMObject {

}
+ (id)objectWithContentsOfFile:(NSString *)file decodingPixelData:(BOOL)decodePixelData;
- (BOOL)isNeededAttribute:(char *)tagString;

@end
