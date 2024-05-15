
#import "WebPortal.h"


@class WebPortalUser;

@interface WebPortal (EmailLog)

-(void)emailNotifications;
-(BOOL)sendNotificationsEmailsTo:(NSArray*)users aboutStudies:(NSArray*)filteredStudies predicate:(NSString*)predicate customText:(NSString*)customText;
-(BOOL)sendNotificationsEmailsTo:(NSArray*)users aboutStudies:(NSArray*)filteredStudies predicate:(NSString*)predicate customText:(NSString*)customText from:(WebPortalUser*) from;

-(void)updateLogEntryForStudy:(NSManagedObject*)study withMessage:(NSString*)message forUser:(NSString*)user ip:(NSString*)ip;

-(WebPortalUser*)newUserWithEmail:(NSString*)email;

- (void) deleteTemporaryUsers:(NSTimer*)timer;

@end
