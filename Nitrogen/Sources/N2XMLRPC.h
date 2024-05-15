#import <Cocoa/Cocoa.h>


@interface N2XMLRPC : NSObject {
}

enum N2XMLRPCOptionMasks {
    N2XMLRPCDontSpecifyStringTypeOptionMask = 1<<0
};

+(NSObject*)ParseElement:(NSXMLNode*)n;
+(NSString*)FormatElement:(NSObject*)o;
+(NSString*)FormatElement:(NSObject*)o options:(NSUInteger)options;

+(NSString*)requestWithMethodName:(NSString*)methodName arguments:(NSArray*)args;
+(NSString*)responseWithValue:(id)value;
+(NSString*)responseWithValue:(id)value options:(NSUInteger)options;

@end
