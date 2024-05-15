#import "ReportPluginFilter.h"


@implementation ReportPluginFilter

- (BOOL)createReportForStudy:(id)study{
	return NO;
}
- (BOOL)deleteReportForStudy:(id)study{
	return NO;
}
- (NSDate *)reportDateForStudy:(id)study{
	return nil;
}

@end
