#import "JPEGExif.h"

@implementation JPEGExif

+ (void) addExif:(NSURL*) url properties:(NSDictionary*) exifDict format: (NSString*) format;
{
	CGImageSourceRef source = CGImageSourceCreateWithURL((CFURLRef)url, NULL);
    if (source)
    {
		
		NSString *type = nil;
		
		if( [format isEqualToString:@"tiff"]) type = @"public.tiff";
		if( [format isEqualToString:@"jpeg"]) type = @"public.jpeg";
		
		CGImageDestinationRef dest = CGImageDestinationCreateWithURL((CFURLRef) url, (CFStringRef) type, 1, nil);
		if ( dest)
		{
			NSMutableDictionary *newProps = [NSMutableDictionary dictionary];

			[newProps setObject: exifDict forKey: (NSString*) kCGImagePropertyExifDictionary];
			CGImageDestinationAddImageFromSource(dest, source, 0, (CFDictionaryRef) newProps);
			
			CFRelease( dest);
		}
		
		CFRelease( source);
	}
}

@end
