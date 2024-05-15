
#import <Cocoa/Cocoa.h>
#import "DCMTKQueryNode.h"

/** \brief Image level DCMTKQueryNode*/
@interface DCMTKImageQueryNode : DCMTKQueryNode
{
	NSString *_studyInstanceUID, *_seriesInstanceUID;
}

- (NSString*) seriesInstanceUID;
- (NSString*) studyInstanceUID;

@end
