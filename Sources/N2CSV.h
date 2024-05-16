#import <Cocoa/Cocoa.h>


@interface N2CSV : NSObject {
}

+(NSString*)quote:(NSString*)str;
+(NSString*)stringFromArray:(NSArray*)array;

@end
