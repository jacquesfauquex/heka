#import "N2CSV.h"
#import "NSString+N2.h"


@implementation N2CSV

+(NSString*)quote:(NSString*)str {
	BOOL doubleQuote = [str contains:@","] || [str contains:@"\n"] || [str contains:@"\""] || [str hasPrefix:@" "] || [str hasSuffix:@" "];
	if (!doubleQuote)
		return str;
	return [NSString stringWithFormat:@"\"%@\"", [str stringByReplacingOccurrencesOfString:@"\"" withString:@"\"\""]];
}

+(NSString*)stringFromArray:(NSArray*)array {
	NSMutableString* str = [NSMutableString string];
	
	for (NSString* istr in array) {
		if (str.length)
			[str appendString:@","];
		[str appendString:[self quote:istr]];
	}
	
	return [[str copy] autorelease];
}

@end
