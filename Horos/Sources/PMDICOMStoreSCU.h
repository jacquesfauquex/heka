#import <Foundation/Foundation.h>


@interface PMDICOMStoreSCU : NSObject {

}


//-(id)initWithCalledAET:(NSString *) callingAET:(NSString *)  hostName:(NSString *) port:(int);
-(BOOL)sendFile:(NSString *)fileName :(int)compressionLevel;
@end
