#import "N2DisclosureBox.h"
@class N2Step;

__deprecated
@interface N2StepView : N2DisclosureBox {
	N2Step* _step;
}

@property(readonly) N2Step* step;

-(id)initWithStep:(N2Step*)step;

@end
