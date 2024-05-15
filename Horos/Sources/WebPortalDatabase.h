
#import "N2ManagedDatabase.h"


@class WebPortalUser;


@interface WebPortalDatabase : N2ManagedDatabase {
}

extern NSString* const WebPortalDatabaseUserEntityName;
extern NSString* const WebPortalDatabaseStudyEntityName;

-(NSEntityDescription*)userEntity;
-(NSEntityDescription*)studyEntity;

-(NSArray*)usersWithPredicate:(NSPredicate*)p;

-(WebPortalUser*)userWithName:(NSString*)name;
-(WebPortalUser*)newUser;

@end
