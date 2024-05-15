#import <Cocoa/Cocoa.h>
//#include <boost/numeric/ublas/matrix.hpp>

@interface NSImage (N2)

-(void)flipImageHorizontally;
-(NSRect)boundingBoxSkippingColor:(NSColor*)color inRect:(NSRect)box;
-(NSRect)boundingBoxSkippingColor:(NSColor*)color;

-(NSImage*)shadowImage;
-(NSImage*)imageWithHue:(CGFloat)hue;
-(NSImage*)imageInverted;

-(NSSize)sizeByScalingProportionallyToSize:(NSSize)targetSize;
-(NSSize)sizeByScalingDownProportionallyToSize:(NSSize)targetSize;
-(NSImage*)imageByScalingProportionallyToSize:(NSSize)targetSize;
-(NSImage*)imageByScalingProportionallyToSizeUsingNSImage:(NSSize)targetSize;
-(NSImage*)imageByScalingProportionallyUsingNSImage:(float)ratio;

@end

@interface N2Image : NSImage {
	NSRect _portion;
	NSSize _inchSize;
}

@property NSSize inchSize;
@property NSRect portion;

-(id)initWithSize:(NSSize)size inches:(NSSize)inches;
-(id)initWithSize:(NSSize)size inches:(NSSize)inches portion:(NSRect)portion;
-(N2Image*)crop:(NSRect)rect;
-(NSPoint)convertPointFromPageInches:(NSPoint)p;
-(NSSize)originalInchSize;
-(float)resolution;

@end
