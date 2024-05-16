#import <N2Step.h>

NSString * const N2StepDidBecomeActiveNotification = @"N2StepDidBecomeActiveNotification";
NSString * const N2StepDidBecomeInactiveNotification = @"N2StepDidBecomeInactiveNotification";
NSString * const N2StepDidBecomeEnabledNotification = @"N2StepDidBecomeEnabledNotification";
NSString * const N2StepDidBecomeDisabledNotification = @"N2StepDidBecomeDisabledNotification";
NSString * const N2StepTitleDidChangeNotification = @"N2StepTitleDidChangeNotification";

@implementation N2Step
@synthesize enclosedView = _enclosedView, title = _title, active = _active, necessary = _necessary, done = _done, enabled = _enabled, shouldStayVisibleWhenInactive = _shouldStayVisibleWhenInactive;
@synthesize defaultButton;

-(id)initWithTitle:(NSString*)aTitle enclosedView:(NSView*)aView {
	_enclosedView = [aView retain];
	_title = [aTitle retain];
	
	_necessary = YES;
	_active = NO;
	_enabled = YES;
	_done = NO;
	
	return self;
}

-(void)dealloc {
	[_enclosedView release];
	[_title release];
	self.defaultButton = NULL;
	[super dealloc];
}

-(void)setActive:(BOOL)active {
	//if (_active != active) {
		_active = active;
		[[NSNotificationCenter defaultCenter] postNotificationName:(active ?N2StepDidBecomeActiveNotification :N2StepDidBecomeInactiveNotification) object:self];
	//}
}

-(void)setEnabled:(BOOL)enabled {
	//if (_enabled != enabled) {
		if (!enabled && _active)
			[self setActive:NO];
		_enabled = enabled;
		[[NSNotificationCenter defaultCenter] postNotificationName:(enabled ?N2StepDidBecomeEnabledNotification :N2StepDidBecomeDisabledNotification) object:self];
	//}
}

-(void)setTitle:(NSString*)title {
	[_title release];
	_title = [title retain];
	[[NSNotificationCenter defaultCenter] postNotificationName:N2StepTitleDidChangeNotification object:self];
}

@end
