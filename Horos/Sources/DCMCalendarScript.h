
#import <Cocoa/Cocoa.h>

/** \brief Runs applescript interaction with iCal */
@interface DCMCalendarScript : NSObject {
	NSAppleScript *compiledScript;
}


- (id)initWithCalendar:(NSString *)calendar;
- (NSMutableArray *)routingDestination;
@end
