#import "NSPreferencePane+OsiriX.h"
#import "PreferencesWindowController.h"
#import "SFHorosAuthorizationView.h"


@implementation NSPreferencePane (OsiriX)

-(BOOL)isUnlocked {
	return ![[NSUserDefaults standardUserDefaults] boolForKey:@"AUTHENTICATION"] || [[(PreferencesWindowController*)[[[self mainView] window] windowController] authView] authorizationState] == SFAuthorizationViewUnlockedState;
}

-(NSNumber*)editable {
	return [NSNumber numberWithBool:[self isUnlocked]];
}

@end
