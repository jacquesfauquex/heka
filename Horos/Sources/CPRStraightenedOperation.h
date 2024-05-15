#import <Cocoa/Cocoa.h>
#import "CPRGeneratorOperation.h"
#import "CPRGeneratorRequest.h"

@interface CPRStraightenedOperation : CPRGeneratorOperation {
    volatile int32_t _outstandingFillOperationCount __attribute__ ((aligned (4)));
    
    float *_floatBytes;
    NSMutableSet *_fillOperations;
	NSOperation *_projectionOperation;
    BOOL _operationExecuting;
    BOOL _operationFinished;
    BOOL _operationFailed;
    
    CGFloat _sampleSpacing; // renerated and cached by the operation based on the width and the length of the bezier
}

- (id)initWithRequest:(CPRStraightenedGeneratorRequest *)request volumeData:(CPRVolumeData *)volumeData;

@property (readonly) CPRStraightenedGeneratorRequest *request;

@end

