#import <Cocoa/Cocoa.h>
#import "DCMTKQueryNode.h"

/** \brief Study level DCMTKQueryNode */
@interface DCMTKStudyQueryNode : DCMTKQueryNode {
    BOOL _sortChildren;
}

- (NSString*) studyInstanceUID;// Match DicomStudy
- (NSString*) studyName;// Match DicomStudy
- (NSNumber*) numberOfImages;// Match DicomStudy
- (NSDate*) dateOfBirth; // Match DicomStudy
- (NSNumber*) noFiles; // Match DicomStudy
@end
