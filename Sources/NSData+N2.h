#import <Cocoa/Cocoa.h>


@interface NSData (N2)

+(NSData*)dataWithHex:(NSString*)hex;
-(NSData*)initWithHex:(NSString*)hex;
+(NSData*)dataWithBase64:(NSString*)base64;
-(NSData*)initWithBase64:(NSString*)base64;
-(NSString*)base64;
-(NSString*)hex;
-(NSData*)md5;

@end
