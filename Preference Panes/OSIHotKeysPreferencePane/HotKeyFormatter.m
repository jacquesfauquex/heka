
#import "HotKeyFormatter.h"


@implementation HotKeyFormatter

- (BOOL)isPartialStringValid:(NSString *)partialString newEditingString:(NSString **)newString errorDescription:(NSString **)error{
	if ([partialString length] > 1)
		return NO;
	return YES;
}

- (NSString *)stringForObjectValue:(id)anObject{
    
    if( [anObject isEqualToString: @"dbl-click"])
        return NSLocalizedString( @"dbl-click", @"keep it short !");
    
    if( [anObject isEqualToString: @"dbl-click + alt"])
        return NSLocalizedString( @"dbl-click + alt", @"keep it short ! dbl-click + alt = double-click + alternate key");
    
    if( [anObject isEqualToString: @"dbl-click + cmd"])
        return NSLocalizedString( @"dbl-click + cmd", @"keep it short ! double-click + command key");
    
	 return [anObject uppercaseString];
}

- (NSString *)editingStringForObjectValue:(id)anObject{
	return anObject;
}


- (BOOL)getObjectValue:(id *)anObject forString:(NSString *)string errorDescription:(NSString **)error{
	*anObject = [[string copy] autorelease];
	return YES;
}




@end
