#import <Cocoa/Cocoa.h>
#import "PreferencesWindowController.h"

/** \brief Category for DCMTK calls for PreferencesWindowController*/

@interface PreferencesWindowController (DCMTK)

- (NSArray*) prepareDICOMFieldsArrays;

@end
