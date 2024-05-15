#import <Cocoa/Cocoa.h>


@class DCMAttributeTag;

@interface AnonymizationTagsPopUpButton : NSPopUpButton {
	DCMAttributeTag* selectedDCMAttributeTag;
}

+(NSMenu*)tagsMenu;
+(NSMenu*)tagsMenuWithTarget:(id)obj action:(SEL)action;

@property (retain,nonatomic) DCMAttributeTag* selectedDCMAttributeTag;

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wincompatible-property-type"
@property(retain,nonatomic) DCMAttributeTag* selectedTag NS_UNAVAILABLE;
#pragma clang diagnostic pop

@end
