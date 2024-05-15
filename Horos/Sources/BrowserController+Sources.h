
#import "BrowserController.h"

@class DataNodeIdentifier, DicomDatabase;

@interface BrowserController (Sources)

-(void)awakeSources;
-(void)deallocSources;

-(void)redrawSources;

-(DataNodeIdentifier*)sourceIdentifierAtRow:(int)row;
-(int)rowForDatabase:(DicomDatabase*)database;
-(DataNodeIdentifier*)sourceIdentifierForDatabase:(DicomDatabase*)database;
-(void)selectCurrentDatabaseSource;

-(int)findDBPath:(NSString*)path dbFolder:(NSString*)DBFolderLocation __deprecated;
-(void)removePathFromSources:(NSString*) path;
@end
