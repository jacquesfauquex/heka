#import "stringAdditions.h"

@implementation NSString (stringAdditions)

- (NSComparisonResult)numericCompare:(NSString *)aString
{
	return [self compare:aString options:NSNumericSearch | NSCaseInsensitiveSearch];
}

@end
