#import <Foundation/Foundation.h>


@interface DCMCharacterSet : NSObject {
	NSStringEncoding encoding;
	NSStringEncoding *encodings;
	NSString *_characterSet;
}

@property(readonly) NSStringEncoding* encodings;
@property(readonly) NSStringEncoding encoding;
@property(readonly) NSString *characterSet, *description;

- (id)initWithCode:(NSString *)characterSet;
- (id)initWithCharacterSet:(DCMCharacterSet *)characterSet;

+ (NSString *) stringWithBytes:(char *) str length:(unsigned) length encodings: (NSStringEncoding*) encodings;
+ (NSStringEncoding)encodingForDICOMCharacterSet:(NSString *)characterSet;

@end
