
#import <Cocoa/Cocoa.h>
#import "PluginFilter.h"

/** \brief  Report Plugin Filter base class */
@interface ReportPluginFilter : PluginFilter {

}

- (BOOL)createReportForStudy:(id)study;
- (BOOL)deleteReportForStudy:(id)study;
- (NSDate *)reportDateForStudy:(id)study;

@end
