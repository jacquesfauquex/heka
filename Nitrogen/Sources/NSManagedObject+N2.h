#import <Cocoa/Cocoa.h>


@interface NSManagedObject (N2)

+(NSString*)UidForXid:(NSString*)xid;
+(NSURL*)UrlForXid:(NSString*)xid;

-(NSString*)XID;
-(NSString*)XIDFilename;
@end
