


#import <Foundation/Foundation.h>
#import <AppKit/NSSplitView.h>

/** \brief Category saves splitView state to User Defaults */
@interface NSSplitView(Defaults)

- (void) restoreDefault: (NSString *) defaultName;
- (void) saveDefault: (NSString *) defaultName;

@end
