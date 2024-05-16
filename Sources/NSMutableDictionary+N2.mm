#import "NSMutableDictionary+N2.h"
#import "NSDictionary+N2.h"


@implementation NSMutableDictionary (N2)

-(void)removeObject:(id)obj
{
    NSString *key = nil;
    do
    {
        key = [self keyForObject: obj];
        if( key)
            [self removeObjectForKey: key];
    }while( key);
}

-(void)setBool:(BOOL)b forKey:(NSString*)key
{
	[self setObject:[NSNumber numberWithBool:b] forKey:key];
}

@end
