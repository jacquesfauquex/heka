#import "N2HexadecimalNumberFormatter.h"


@implementation N2HexadecimalNumberFormatter

-(NSString*)stringForObjectValue:(NSNumber*)number {
    if (![number isKindOfClass:[NSNumber class]])
        return NULL;
	
	NSString* format = [NSString stringWithFormat:@"0x%%0%dX", (int) self.formatWidth];
	
    return [NSString stringWithFormat:format, [number intValue]];
}

-(BOOL)getObjectValue:(id*)outNumber forString:(NSString*)string errorDescription:(NSString**)outError {
	NSScanner* scanner = [NSScanner scannerWithString:string];

	unsigned int value;
	BOOL success = [scanner scanHexInt:&value];
	
	if (success)
		*outNumber = [NSNumber numberWithUnsignedInt:value];
	return success;
}

-(NSAttributedString*)attributedStringForObjectValue:(NSNumber*)number withDefaultAttributes:(NSDictionary*)attributes {
	/*if (![number isKindOfClass:[NSNumber class]])
        return NULL;
	
	return [[[NSAttributedString alloc] initWithString:[self stringForObjectValue:number] attributes:attributes] autorelease];*/
	
	return NULL;
}

@end

