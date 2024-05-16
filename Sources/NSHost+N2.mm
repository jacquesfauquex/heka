
#import "NSHost+N2.h"

@implementation NSHost (N2)

+(NSHost*)hostWithAddressOrName:(NSString*)str {
    if (![str rangeOfCharacterFromSet:[NSCharacterSet letterCharacterSet]].length)
        return [NSHost hostWithAddress:str];
	else return [NSHost hostWithName:str];
}

@end
