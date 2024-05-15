#import <N2Window.h>
#import <N2View.h>
#import <N2Operators.h>


@implementation N2Window

-(id)initWithContentRect:(NSRect)contentRect styleMask:(NSUInteger)windowStyle backing:(NSBackingStoreType)bufferingType defer:(BOOL)deferCreation {
	self = [super initWithContentRect:contentRect styleMask:windowStyle backing:bufferingType defer:deferCreation];
	[self setContentView:[[[N2View alloc] initWithFrame:[[self contentView] frame]] autorelease]];
	return self;
}

@end
