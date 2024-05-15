#import <Cocoa/Cocoa.h>


@interface CIADICOMField : NSObject {
	int group, element;
	NSString *name;
}

- (id)initWithGroup:(int)g element:(int)e name:(NSString*)n;
- (int)group;
- (int)element;
- (NSString*)name;
- (NSString*)title;

@end
