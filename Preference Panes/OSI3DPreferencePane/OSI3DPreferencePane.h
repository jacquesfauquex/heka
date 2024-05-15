#import <PreferencePanes/PreferencePanes.h>

@interface OSI3DPreferencePanePref : NSPreferencePane 
{
//	IBOutlet NSSlider						*bestRenderingSlider, *max3DTextureSlider, *max3DTextureSliderShading;
//	IBOutlet NSTextField					*bestRenderingString, *max3DTextureString, *max3DTextureStringShading;
//	IBOutlet NSTextField					*recommandations;

    IBOutlet NSWindow *mainWindow;
    
    id _tlos;
}

- (void) mainViewDidLoad;

//- (IBAction) setBestRendering: (id) sender;
//- (IBAction) setMax3DTexture: (id) sender;
//- (IBAction) setMax3DTextureShading: (id) sender;
@end
