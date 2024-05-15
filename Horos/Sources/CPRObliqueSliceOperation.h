#import <Cocoa/Cocoa.h>
#import "CPRGeneratorOperation.h"
#import "CPRGeneratorRequest.h"

@interface CPRObliqueSliceOperation : CPRGeneratorOperation {
    volatile int32_t _oustandingFillOperationCount __attribute__ ((aligned (4)));

    float *_floatBytes;
    NSMutableSet *_fillOperations;
    NSOperation *_projectionOperation;

    BOOL _operationExecuting;
    BOOL _operationFinished;
    BOOL _operationFailed;    
}

- (id)initWithRequest:(CPRObliqueSliceGeneratorRequest *)request volumeData:(CPRVolumeData *)volumeData;

@property (readonly) CPRObliqueSliceGeneratorRequest *request;

@end
