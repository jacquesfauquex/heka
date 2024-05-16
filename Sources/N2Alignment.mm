#import "N2Alignment.h"

const N2Alignment N2Top = 1<<0;
const N2Alignment N2Bottom = 1<<1;
const N2Alignment N2Left = 1<<2;
const N2Alignment N2Right = 1<<3;

NSRect NSRectCenteredInRect(NSRect smallRect, NSRect bigRect) {
	NSRect centeredRect;
    centeredRect.size = smallRect.size;
	
    centeredRect.origin.x = (bigRect.size.width - smallRect.size.width) / 2.0;
    centeredRect.origin.y = (bigRect.size.height - smallRect.size.height) / 2.0;
	
    return centeredRect;
}
