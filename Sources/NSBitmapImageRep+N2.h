#import <Cocoa/Cocoa.h>


@interface NSBitmapImageRep (N2)

-(void)setColor:(NSColor*)color __deprecated; // buggy in Retina...
-(NSImage*)image;
-(NSBitmapImageRep*)repUsingColorSpaceName:(NSString*)colorSpaceName;

-(void)ATMask:(float)level DEPRECATED_ATTRIBUTE;
-(NSBitmapImageRep*)smoothen:(NSUInteger)margin;
//-(NSBitmapImageRep*)convolveWithFilter:(const boost::numeric::ublas::matrix<float>&)filter fillPixel:(NSUInteger[])fillPixel;
//-(NSBitmapImageRep*)fftConvolveWithFilter:(const boost::numeric::ublas::matrix<float>&)filter fillPixel:(NSUInteger[])fillPixel;

@end
