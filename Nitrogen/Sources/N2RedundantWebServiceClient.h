
#import "N2WebServiceClient.h"


@interface N2RedundantWebServiceClient : N2WebServiceClient {
	NSArray* _urls;
}

@property(retain) NSArray* urls;

@end
