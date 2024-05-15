

#import <Cocoa/Cocoa.h>
/** \brief OutlineView for BrowserController */
@interface MyOutlineView : NSOutlineView
{
//	NSArray	*allColumns; // we once removed and added columns, now we use the isHidden flag...
}

- (void)removeAllColumns __deprecated; // hideAllColumns
- (void)hideAllColumns;
- (NSTableColumn *)initialColumnWithIdentifier:(id)identifier;
- (BOOL)isColumnWithIdentifierVisible:(id)identifier;
- (void)setColumnWithIdentifier:(id)identifier visible:(BOOL)visible;
- (void)setInitialState __deprecated;
- (void)restoreColumnState:(NSObject *)columnState;
- (NSObject<NSCoding>*)columnState;
- (NSArray*) allColumns __deprecated; // just use tableColumns

@end
