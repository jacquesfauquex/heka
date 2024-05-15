#import <Cocoa/Cocoa.h>

@class DicomDatabase;

/** \brief Managed network logging */
@interface LogManager : NSObject
{
	NSMutableDictionary *_currentLogs;
}

+ (id) currentLogManager;
- (void) resetLogs;
- (void) addLogLine: (NSDictionary*) dict;

@end
