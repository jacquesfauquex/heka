
#import <Cocoa/Cocoa.h>

@class CPRGeneratorRequest;
@class CPRVolumeData;

@interface CPRGeneratorOperation : NSOperation {
    CPRVolumeData *_volumeData;
    CPRGeneratorRequest *_request;
    CPRVolumeData *_generatedVolume;
}

- (id)initWithRequest:(CPRGeneratorRequest *)request volumeData:(CPRVolumeData *)volumeData;

@property (readonly) CPRGeneratorRequest *request;
@property (readonly) CPRVolumeData *volumeData;
@property (readonly) BOOL didFail;
@property (readwrite, retain) CPRVolumeData *generatedVolume;

@end

