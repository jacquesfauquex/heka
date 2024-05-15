
#import <Cocoa/Cocoa.h>


@interface NSObject (Scripting)

-(NSAppleEventDescriptor*)appleEventDescriptor;

@end


@interface NSAppleEventDescriptor (Scripting)

-(id)object;
+(NSDictionary*)dictionaryWithArray:(NSArray*)array;

@end
