#import <Foundation/Foundation.h>
#import <CoreMedia/CoreMedia.h>
#import <AVFoundation/AVFoundation.h>

/** \brief QuickTime export */
@interface QuicktimeExport : NSObject
{
	id						object;
	SEL						selector;
	long					numberOfFrames;
    unsigned long			codec;
	long					quality;
	
	NSSavePanel				*panel;
	NSArray					*exportTypes;
	
    IBOutlet NSTextField    *rateValue;
    
	IBOutlet NSView			*view;
    IBOutlet NSPopUpButton	*type;
    
    id _tlos;
}

+ (CVPixelBufferRef) CVPixelBufferFromNSImage:(NSImage *)image;
- (id) initWithSelector:(id) o :(SEL) s :(long) f;
- (NSString *) createMovieQTKit:(BOOL) openIt :(BOOL) produceFiles :(NSString*) name;
- (NSString *) createMovieQTKit:(BOOL) openIt :(BOOL) produceFiles :(NSString*) name :(NSInteger)framesPerSecond;
@end

