
#import "N2View.h"
@class N2Steps, N2Step, N2StepView, N2ColumnLayout;

__deprecated
@interface N2StepsView : N2View {
	IBOutlet N2Steps* _steps;
}

-(void)stepsDidAddStep:(NSNotification*)notification;
-(N2StepView*)stepViewForStep:(N2Step*)step;
-(void)layOut;

@end
