#import <Cocoa/Cocoa.h>

@interface NSString (SymlinksAndAliases)

- (NSString *)stringByResolvingSymlinksAndAliases;
- (NSString *)stringByIterativelyResolvingSymlinkOrAlias;

- (NSString *)stringByResolvingSymlink;
- (NSString *)stringByConditionallyResolvingSymlink;

- (NSString *)stringByResolvingAlias;
- (NSString *)stringByConditionallyResolvingAlias;

@end
