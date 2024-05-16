#import <Cocoa/Cocoa.h>

@interface NSInvocation (N2)

+(NSInvocation*)invocationWithSelector:(SEL)sel target:(id)target;
+(NSInvocation*)invocationWithSelector:(SEL)sel target:(id)target argument:(id)arg;
-(void)setArgumentObject:(id)o atIndex:(NSUInteger)i;
-(id)returnValue;

@end
