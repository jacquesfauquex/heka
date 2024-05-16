#import <Cocoa/Cocoa.h>


@interface NSDictionary (N2)

-(id)objectForKey:(id)k ofClass:(Class)cl;
-(id)keyForObject:(id)obj;
-(id)deepMutableCopy;

@end
