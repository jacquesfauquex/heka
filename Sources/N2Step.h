#import <Cocoa/Cocoa.h>

extern NSString * const __deprecated N2StepDidBecomeActiveNotification;
extern NSString * const __deprecated N2StepDidBecomeInactiveNotification;
extern NSString * const __deprecated N2StepDidBecomeEnabledNotification;
extern NSString * const __deprecated N2StepDidBecomeDisabledNotification;
extern NSString * const __deprecated N2StepTitleDidChangeNotification;

__deprecated
@interface N2Step : NSObject {
	NSString* _title;
	NSView* _enclosedView;
	NSButton* defaultButton;
	BOOL _necessary, _active, _enabled, _done, _shouldStayVisibleWhenInactive;
}

@property(nonatomic, retain) NSString* title;
@property(readonly) NSView* enclosedView;
@property(retain) NSButton* defaultButton;
@property(getter=isNecessary) BOOL necessary;
@property(nonatomic, getter=isActive) BOOL active;
@property(nonatomic, getter=isEnabled) BOOL enabled;
@property(getter=isDone) BOOL done;
@property BOOL shouldStayVisibleWhenInactive;

-(id)initWithTitle:(NSString*)title enclosedView:(NSView*)view;

@end
