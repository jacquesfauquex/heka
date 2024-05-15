
#import "DCMAttributeTag.h"


@interface O2DicomPredicateEditorDCMAttributeTag : DCMAttributeTag {
    NSString* _description;
    NSString* _cskey;
}

+ (id)tagWithGroup:(int)group element:(int)element vr:(NSString*)vr name:(NSString*)name description:(NSString*)description cskey:(NSString*)cskey;
+ (id)tagWithGroup:(int)group element:(int)element vr:(NSString*)vr name:(NSString*)name description:(NSString*)description;

- (NSString*)cskey;

@end
