#import <Cocoa/Cocoa.h>


@interface NSPanel (N2)

+(NSPanel*)alertWithTitle:(NSString*)title message:(NSString*)message defaultButton:(NSString*)defaultButton alternateButton:(NSString*)alternateButton icon:(NSImage*)icon;
+(NSPanel*)alertWithTitle:(NSString*)title message:(NSString*)message defaultButton:(NSString*)defaultButton alternateButton:(NSString*)alternateButton icon:(NSImage*)icon sheet:(BOOL)sheet;

@end
