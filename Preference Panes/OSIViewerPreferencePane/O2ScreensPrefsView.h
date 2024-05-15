
#import <Cocoa/Cocoa.h>

@interface O2ScreensPrefsView : NSControl {
    NSMutableArray* _records;
    id /*_hoveringRecord, */_activeRecord;
}

@end
