
#import <Cocoa/Cocoa.h>
#import "DCMTKQueryNode.h"
#import "DCMTKStudyQueryNode.h"

/** \brief Series level DCMTKQueryNode */
@interface DCMTKSeriesQueryNode : DCMTKQueryNode
{
	NSString *_studyInstanceUID;
    DCMTKStudyQueryNode *study;
}

@property (assign) DCMTKStudyQueryNode *study;

- (NSString*) studyInstanceUID;
- (NSString*) seriesInstanceUID;

@end
