#import "stringNumericCompare.h"
#import <Foundation/Foundation.h>

@implementation NSString (stringNumericCompare)

-(NSComparisonResult)numericCompare:(NSString *)aString
{
    return [self compare:aString options:NSNumericSearch | NSCaseInsensitiveSearch];
}

@end
