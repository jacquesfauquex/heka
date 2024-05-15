
#import <Cocoa/Cocoa.h>


@interface BrowserMatrix : NSMatrix <NSDraggingSource, NSPasteboardItemDataProvider>
{
	BOOL avoidRecursive;
}

@end
