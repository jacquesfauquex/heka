
#import <Foundation/Foundation.h>


@interface WADODownload : NSObject
{
	volatile int32_t WADOThreads __attribute__ ((aligned (4)));
    int WADOTotal, countOfSuccesses;
    int WADOGrandTotal, WADOBaseTotal;
    unsigned long totalData, receivedData;
	NSMutableDictionary *WADODownloadDictionary, *logEntry;
	BOOL showErrorMessage, firstWadoErrorDisplayed, _abortAssociation;
    NSTimeInterval firstReceivedTime, lastStatusUpdate;
    NSString *baseStatus;
}

@property BOOL _abortAssociation, showErrorMessage;
@property int countOfSuccesses, WADOGrandTotal, WADOBaseTotal;
@property unsigned long totalData, receivedData;
@property (retain) NSString *baseStatus;

- (void) WADODownload: (NSArray*) urlToDownload;

@end
