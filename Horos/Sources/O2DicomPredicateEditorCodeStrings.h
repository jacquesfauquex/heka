
#import <Foundation/Foundation.h>

@class DCMAttributeTag;

@interface O2DicomPredicateEditorCodeStrings : NSObject

+ (NSDictionary*)codeStringsForTag:(DCMAttributeTag*)tag;

@end

