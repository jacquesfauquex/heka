#import <Cocoa/Cocoa.h>
#import "CPRGeneratorOperation.h"
#import "CPRGeneratorRequest.h"

@interface CPRStretchedOperation : CPRGeneratorOperation
{
    volatile int32_t _outstandingFillOperationCount __attribute__ ((aligned (4)));
    
    float *_floatBytes;
    NSMutableSet *_fillOperations;
	NSOperation *_projectionOperation;
    BOOL _operationExecuting;
    BOOL _operationFinished;
    BOOL _operationFailed;
    
    CGFloat _sampleSpacing;
}

- (id)initWithRequest:(CPRStretchedGeneratorRequest *)request volumeData:(CPRVolumeData *)volumeData;

@property (readonly) CPRStretchedGeneratorRequest *request;

@end
