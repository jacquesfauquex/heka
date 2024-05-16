#import <Cocoa/Cocoa.h>
#include <sys/stat.h>


@interface N2DirectoryEnumerator : NSDirectoryEnumerator {
@private
	NSString* basepath;
	NSString* currpath;
	NSMutableArray* DIRs;
	NSUInteger counter, max;
	BOOL _filesOnly;
	BOOL _recursive;
}

@property BOOL filesOnly;
@property BOOL recursive;

-(id)initWithPath:(NSString*)path maxNumberOfFiles:(NSInteger)n;

- (int)stat:(struct stat*)s;

@end
