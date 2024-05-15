
#import <Foundation/Foundation.h>

@interface NSString(NumberStuff)
- (BOOL)holdsIntegerValue;
@end


/** \brief  Reads and parses DICOMDIRs */

@interface DicomDirParser : NSObject
{
	NSString				*data, *dirpath;
}

- (id) init:(NSString*) file;
- (void) parseArray:(NSMutableArray*) files;

@end
