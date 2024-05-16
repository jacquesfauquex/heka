
#import <Cocoa/Cocoa.h>


@interface NSXMLNode (N2)

+(id)elementWithName:(NSString*)name text:(NSString*)text;
+(id)elementWithName:(NSString*)name unsignedInt:(NSUInteger)value;
+(id)elementWithName:(NSString*)name bool:(BOOL)value;
-(NSXMLNode*)childNamed:(NSString*)childName;

@end
