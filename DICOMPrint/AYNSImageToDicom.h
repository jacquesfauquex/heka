#import <Cocoa/Cocoa.h>
#import "ViewerController.h"
#import "DCMView.h"
#import "DCMPix.h"

enum
{
	eCurrentImage = 0,
	eKeyImages = 1,
	eAllImages = 2,
};

struct rawData
{
	long bytesWritten;
    long height;
    long width;
};


/** \brief Creates DICOM print images */
@interface AYNSImageToDicom : NSObject
{
	NSMutableData	*m_ImageDataBytes;
}

@property (nonatomic, assign) BOOL prepareForDCMTK;

- (NSArray *) dicomFileListForViewer: (ViewerController *) currentViewer destinationPath: (NSString *) destPath options: (NSDictionary*) options asColorPrint: (BOOL) colorPrint withAnnotations: (BOOL) annotations;
- (NSArray *) dicomFileListForViewer: (ViewerController *) currentViewer destinationPath: (NSString *) destPath options: (NSDictionary*) options fileList: (NSArray *) fileList asColorPrint: (BOOL) colorPrint withAnnotations: (BOOL) annotations;

@end
