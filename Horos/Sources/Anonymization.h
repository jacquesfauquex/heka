#import <Cocoa/Cocoa.h>


@class DCMAttributeTag, AnonymizationPanelController, AnonymizationSavePanelController;

@interface Anonymization : NSObject

+(DCMAttributeTag*)tagFromString:(NSString*)k;
+(NSArray*)tagsValuesArrayFromDictionary:(NSDictionary*)dic;
+(NSDictionary*)tagsValuesDictionaryFromArray:(NSArray*)arr;
+(NSArray*)tagsArrayFromStringsArray:(NSArray*)strings;

+(AnonymizationPanelController*)showPanelForDefaultsKey:(NSString*)defaultsKey modalForWindow:(NSWindow*)window modalDelegate:(id)delegate didEndSelector:(SEL)sel representedObject:(id)representedObject;
+(AnonymizationSavePanelController*)showSavePanelForDefaultsKey:(NSString*)defaultsKey modalForWindow:(NSWindow*)window modalDelegate:(id)delegate didEndSelector:(SEL)sel representedObject:(id)representedObject;

+(BOOL)tagsValues:(NSArray*)a1 isEqualTo:(NSArray*)a2;

+(NSDictionary*)anonymizeFiles:(NSArray*)files dicomImages: (NSArray*) dicomImages toPath:(NSString*)dirPath withTags:(NSArray*)intags;

+(NSString*) templateDicomFile;

@end
