
#import "N2Layout.h"

__deprecated
@interface N2ColumnLayout : N2Layout {
	NSArray* _columnDescriptors;
	NSMutableArray* _rows;
}

-(id)initForView:(N2View*)view columnDescriptors:(NSArray*)columnDescriptors controlSize:(NSControlSize)controlSize;

-(NSArray*)rowAtIndex:(NSUInteger)index;
-(NSUInteger)appendRow:(NSArray*)row;
-(void)insertRow:(NSArray*)row atIndex:(NSUInteger)index;
-(void)removeRowAtIndex:(NSUInteger)index;
-(void)removeAllRows;

#pragma mark Deprecated

-(NSArray*)lineAtIndex:(NSUInteger)index DEPRECATED_ATTRIBUTE;
-(NSUInteger)appendLine:(NSArray*)line DEPRECATED_ATTRIBUTE;
-(void)insertLine:(NSArray*)line atIndex:(NSUInteger)index DEPRECATED_ATTRIBUTE;
-(void)removeLineAtIndex:(NSUInteger)index DEPRECATED_ATTRIBUTE;
-(void)removeAllLines DEPRECATED_ATTRIBUTE;

@end
