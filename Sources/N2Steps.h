#import <Cocoa/Cocoa.h>

@class N2Step; //, N2StepsView;

extern NSString * const __deprecated N2StepsDidAddStepNotification;
extern NSString * const __deprecated N2StepsWillRemoveStepNotification;
extern NSString * const __deprecated N2StepsNotificationStep;

__deprecated
@interface N2Steps : NSArrayController {
//	IBOutlet N2StepsView* _view;
	N2Step* _currentStep;
	IBOutlet id _delegate;
}

@property(retain) id delegate;
@property(nonatomic, assign) N2Step* currentStep;
//	@property(readonly) N2StepsView* view;

-(void)enableDisableSteps;

-(BOOL)hasNextStep;
-(BOOL)hasPreviousStep;

-(IBAction)stepDone:(id)sender;
-(IBAction)nextStep:(id)sender;
-(IBAction)previousStep:(id)sender;
-(IBAction)skipStep:(id)sender;
-(IBAction)stepValueChanged:(id)sender;
-(IBAction)reset:(id)sender;

-(void)setCurrentStep:(N2Step*)step;

@end

@interface NSObject (N2StepsDelegate)

-(void)steps:(N2Steps*)steps willBeginStep:(N2Step*)step __deprecated;
-(void)steps:(N2Steps*)steps valueChanged:(id)sender __deprecated;
-(BOOL)steps:(N2Steps*)steps shouldValidateStep:(N2Step*)step __deprecated;
-(void)steps:(N2Steps*)steps validateStep:(N2Step*)step __deprecated;

@end
