#import "NSImage+OsiriX.h"
#import "N2Debug.h"

#include "options.h"

extern unsigned char* compressJPEG(int inQuality, unsigned char* inImageBuffP, int inImageHeight, int inImageWidth, int monochrome, int *destSize);
extern NSRecursiveLock* PapyrusLock;

@implementation NSImage (OsiriX)

-(NSData*)JPEGRepresentationWithQuality:(CGFloat)quality
{
	NSBitmapImageRep* imageRep = [NSBitmapImageRep imageRepWithData:self.TIFFRepresentation];
	NSData* result = NULL;
	NSDictionary* imageProps = [NSDictionary dictionaryWithObject:[NSNumber numberWithFloat:quality]
                                                               forKey:NSImageCompressionFactor];
	result = [imageRep representationUsingType:NSJPEGFileType properties:imageProps];
	
	return result;	
}

@end

