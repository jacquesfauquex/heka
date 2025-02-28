
#import "WebPortalConnection.h"

@class DicomStudy;

@interface WebPortalConnection (Data)

+(NSArray*)MakeArray:(id)obj;

-(void)getWidth:(CGFloat*)width height:(CGFloat*)height fromImagesArray:(NSArray*)imagesArray;
-(void)getWidth:(CGFloat*)width height:(CGFloat*)height fromImagesArray:(NSArray*)imagesArray minSize:(NSSize)minSize maxSize:(NSSize)maxSize;

-(void)processLoginHtml;
-(void)processIndexHtml;
-(void)processMainHtml;
-(void)processStudyListHtml;
-(void)processLogsListHtml;
-(void)processKeyROIsImagesHtml;
-(void)processSeriesHtml;
-(void)processStudyHtml;
-(void)processStudyHtml: (NSString*) xid;
-(void)processPasswordForgottenHtml;
-(void)processAccountHtml;

-(void)processAdminIndexHtml;
-(void)processAdminUserHtml;

-(void)processStudyListJson;
-(void)processSeriesJson;
-(void)processAlbumsJson;
-(void)processSeriesListJson;

-(void)processWado;

-(void)processWeasisJnlp;
-(void)processWeasisXml;

-(void)processThumbnail;
-(void)processReport;
-(void)processSeriesPdf;
-(void)processZip;
-(void)processImage;
-(void)processImageAsScreenCapture: (BOOL) asDisplayed;
-(void)processMovie;

@end

