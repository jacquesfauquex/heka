#import "AppControllerDCMTKCategory.h"

#undef verify

#include "osconfig.h"
#include "dcmjpeg/djdecode.h"  /* for dcmjpeg decoders */
#include "dcmjpeg/djencode.h"  /* for dcmjpeg encoders */
#include "dcrledrg.h"  /* for DcmRLEDecoderRegistration */
#include "dcrleerg.h"  /* for DcmRLEEncoderRegistration */

#include "dcmjpls/djdecode.h" //JPEG-LS
#include "dcmjpls/djencode.h" //JPEG-LS

extern int gPutSrcAETitleInSourceApplicationEntityTitle, gPutDstAETitleInPrivateInformationCreatorUID;

@implementation AppController (AppControllerDCMTKCategory)

- (void)initDCMTK
{
    // register global JPEG decompression codecs
    DJDecoderRegistration::registerCodecs();
    DJLSDecoderRegistration::registerCodecs();
    
    // register global JPEG compression codecs
    DJEncoderRegistration::registerCodecs(
	 	ECC_lossyRGB,
		EUC_never,
		OFFalse,
		OFFalse,
		0,
		0,
		0,
		OFTrue,
		ESS_444,
		OFFalse,
		OFFalse,
		0,
		0,
		0.0,
		0.0,
		0,
		0,
		0,
		0,
		OFTrue,
		OFTrue,
		OFFalse,
		OFFalse,
		OFTrue);
    
    DJLSEncoderRegistration::registerCodecs();
    
    // register RLE compression codec
    DcmRLEEncoderRegistration::registerCodecs();

    // register RLE decompression codec
    DcmRLEDecoderRegistration::registerCodecs();
    
    gPutSrcAETitleInSourceApplicationEntityTitle = [[NSUserDefaults standardUserDefaults] boolForKey: @"putSrcAETitleInSourceApplicationEntityTitle"];
    gPutDstAETitleInPrivateInformationCreatorUID = [[NSUserDefaults standardUserDefaults] boolForKey: @"putDstAETitleInPrivateInformationCreatorUID"];
}
- (void)destroyDCMTK
{
    // deregister JPEG codecs
    DJDecoderRegistration::cleanup();
    DJEncoderRegistration::cleanup();

    // deregister RLE codecs
    DcmRLEDecoderRegistration::cleanup();
    DcmRLEEncoderRegistration::cleanup();
}

@end
