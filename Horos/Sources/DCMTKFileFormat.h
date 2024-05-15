
#import "DCMPix.h"

@interface DCMTKFileFormat : NSObject
{
    void *dcmtkDcmFileFormat;
}
@property void *dcmtkDcmFileFormat;

- (id) initWithFile: (NSString*) file;

@end
