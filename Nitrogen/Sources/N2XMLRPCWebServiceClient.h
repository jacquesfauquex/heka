#import "N2RedundantWebServiceClient.h"


@interface N2XMLRPCWebServiceClient : N2RedundantWebServiceClient {
}

-(id)execute:(NSString*)methodName arguments:(NSArray*)args;

@end
