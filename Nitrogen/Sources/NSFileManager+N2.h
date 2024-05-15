#import <Cocoa/Cocoa.h>
#import "N2DirectoryEnumerator.h"


@interface NSFileManager (N2)

-(void) moveItemAtPathToTrash: (NSString*) path;
-(NSString*)findSystemFolderOfType:(int)folderType forDomain:(int)domain __deprecated;
-(NSString*)userApplicationSupportFolderForApp;
-(NSString*)tmpFilePathInDir:(NSString*)dirPath;
-(NSString*)tmpDirPath;
-(NSString*)tmpFilePathInTmp;
-(NSString*)confirmDirectoryAtPath:(NSString*)dirPath;
-(NSString*)confirmNoIndexDirectoryAtPath:(NSString*)path;
-(NSUInteger)sizeAtPath:(NSString*)path __deprecated;
-(NSUInteger)sizeAtFSRef:(FSRef*)theFileRef __deprecated;
-(BOOL)copyItemAtPath:(NSString*)srcPath toPath:(NSString*)dstPath byReplacingExisting:(BOOL)replace error:(NSError**)err;

-(BOOL)applyFileModeOfParentToItemAtPath:(NSString*)path;

-(NSString*)destinationOfAliasAtPath:(NSString*)path __deprecated;
-(NSString*)destinationOfAliasOrSymlinkAtPath:(NSString*)path __deprecated;
-(NSString*)destinationOfAliasOrSymlinkAtPath:(NSString*)path resolved:(BOOL*)r __deprecated;

-(N2DirectoryEnumerator*)enumeratorAtPath:(NSString*)path limitTo:(NSInteger)maxNumberOfFiles;
-(N2DirectoryEnumerator*)enumeratorAtPath:(NSString*)path filesOnly:(BOOL)filesOnly;
-(N2DirectoryEnumerator*)enumeratorAtPath:(NSString*)path filesOnly:(BOOL)filesOnly recursive:(BOOL)recursive;

@end
