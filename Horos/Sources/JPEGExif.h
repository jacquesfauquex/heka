#import <Cocoa/Cocoa.h>

/** \brief add exif to JPEG */
@interface JPEGExif : NSObject {

}

+ (void) addExif:(NSURL*) url properties:(NSDictionary*) exifDict format: (NSString*) format;

@end
