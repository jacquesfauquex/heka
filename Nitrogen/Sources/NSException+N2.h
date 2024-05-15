#import <Cocoa/Cocoa.h>


extern NSString* const N2ErrorDomain;


@interface NSException (N2)

-(NSString*)stackTrace;
-(NSString*)printStackTrace;

@end
