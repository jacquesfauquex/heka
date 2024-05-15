
#import <Cocoa/Cocoa.h>

@class DicomStudy, WebPortalUser;

@interface WebPortalStudy : NSManagedObject

@property (nonatomic, retain) NSDate * dateAdded;
@property (nonatomic, retain) NSString * patientUID;
@property (nonatomic, retain) NSString * studyInstanceUID;
@property (nonatomic, retain) WebPortalUser * user;

@property (readonly) DicomStudy* study;

@end
