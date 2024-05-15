
#import <Foundation/Foundation.h>

@interface WADOXML : NSObject <NSXMLParserDelegate>
{
    NSMutableDictionary *studies;
    
    NSString *studyInstanceUID, *seriesInstanceUID, *SOPInstanceUID;
    NSString *wadoURL;
}
@property (readonly) NSMutableDictionary *studies;
@property (retain) NSString *studyInstanceUID, *seriesInstanceUID, *SOPInstanceUID, *wadoURL;

- (void) parseURL: (NSURL*) url;
- (NSArray*) getWADOUrls;

@end
