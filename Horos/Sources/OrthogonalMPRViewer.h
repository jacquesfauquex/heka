#import <Cocoa/Cocoa.h>
#import "ViewerController.h"
#import "OrthogonalMPRController.h"
#import "OrthogonalMPRView.h"
#import "OrthogonalMPRController.h"
#import "Window3DController.h"

#import "KBPopUpToolbarItem.h"

@class DICOMExport;
@class KBPopUpToolbarItem;

/** \brief  Window Controller for Orthogonal MPR */

typedef enum {SyncSeriesStateOff=0, SyncSeriesStateDisable=1, SyncSeriesStateEnable=2} SyncSeriesState;
typedef enum {SyncSeriesScopeAllSeries, SyncSeriesScopeSamePatient, SyncSeriesScopeSameStudy} SyncSeriesScope;
typedef enum {SyncSeriesBehaviorAbsolutePosWithSameStudy, SyncSeriesBehaviorRelativePos, SyncSeriesBehaviorAbsolutePos} SyncSeriesBehavior;

@interface OrthogonalMPRViewer : Window3DController <NSWindowDelegate, NSSplitViewDelegate, NSToolbarDelegate>
{
    ViewerController					*viewer;

	IBOutlet OrthogonalMPRController	*controller;
	IBOutlet NSSplitView				*splitView;
	
	NSToolbar							*toolbar;
    IBOutlet NSView						*toolsView, *ThickSlabView;
	IBOutlet NSMatrix					*toolsMatrix;
	BOOL								isFullWindow;
    long								displayResliceAxes;
    
	IBOutlet NSTextField				*thickSlabTextField;
	IBOutlet NSSlider					*thickSlabSlider;
	IBOutlet NSButton					*thickSlabActivated;
	IBOutlet NSPopUpButton				*thickSlabPopup;
	
	IBOutlet NSWindow					*dcmExportWindow;
	IBOutlet NSMatrix					*dcmSelection, *dcmFormat;
	IBOutlet NSSlider					*dcmInterval, *dcmFrom, *dcmTo;
	IBOutlet NSTextField				*dcmSeriesName, *dcmFromTextField, *dcmToTextField, *dcmIntervalTextField, *dcmCountTextField;
	IBOutlet NSBox						*dcmBox;
	DICOMExport							*exportDCM;
	
    IBOutlet NSView						*WLWWView;
	NSData								*transferFunction;	//For opacity
	
	// 4D
	IBOutlet NSView						*movieView;
	IBOutlet NSTextField				*movieTextSlide;
	IBOutlet NSButton					*moviePlayStop;
	IBOutlet NSSlider					*movieRateSlider;
	IBOutlet NSSlider					*moviePosSlider;
	short								curMovieIndex, maxMovieIndex;
	NSTimeInterval						lastTime, lastMovieTime;
	NSTimer								*movieTimer;
    
    // SyncSeries
    KBPopUpToolbarItem                  *syncSeriesToolbarItem;
    SyncSeriesState                     syncSeriesState ;
    SyncSeriesBehavior                  syncSeriesBehavior;
  
    float                               syncOriginPosition[3];
}

- (id) initWithPixList: (NSMutableArray*) pixList :(NSArray*) filesList :(NSData*) vData :(ViewerController*) vC :(ViewerController*) bC;

- (OrthogonalMPRController*) controller;

- (BOOL) is2DViewer;
- (ViewerController*) viewer;

- (short) curMovieIndex;
- (short) maxMovieIndex;
- (void) ApplyCLUTString:(NSString*) str;
- (void) setWLWW:(float) iwl :(float) iww;
- (void) setCurWLWWMenu: (NSString*) wlww;
- (void)applyWLWWForString:(NSString *)menuString;
- (void) flipVolume;
- (DCMView*) keyView;

// SyncSeries between MPR viewers
- (void) syncSeriesScopeAction:(id) sender;
- (void) syncSeriesBehaviorAction:(id) sender;
- (void) syncSeriesStateAction:(id) sender;
- (void) syncSeriesAction:(id) sender;

@property (nonatomic,retain) KBPopUpToolbarItem *syncSeriesToolbarItem;
@property (nonatomic,assign) SyncSeriesState syncSeriesState;
@property (nonatomic,assign) SyncSeriesBehavior syncSeriesBehavior;

- (float*) syncOriginPosition;
- (void) syncSeriesNotification:(NSNotification*)notification;
- (void) posChangeNotification:(NSNotification*)notification;

+ (SyncSeriesScope) syncSeriesScope;
+ (void) getDICOMCoords:(id)viewer :(float*) location;
+ (void) resetSyncOriginPosition:(id)viewer;
+ (void) initSyncSeriesProperties:(id)viewer;

+ (void) syncSeriesScopeAction:(id) sender :(id)viewer;
+ (void) syncSeriesBehaviorAction:(id) sender :(id) viewer;
+ (void) syncSeriesStateAction:(id) sender :(id) viewer;
+ (void) syncSeriesAction:(id) sender :(id)viewer;

+ (void) updateSyncSeriesState:(id)viewer :(SyncSeriesState) newState;
+ (void) updateSyncSeriesScope:(id)viewer :(SyncSeriesScope) newScope ;
+ (void) updateSyncSeriesBehavior:(id)viewer :(SyncSeriesBehavior) newBehavior;
+ (void) updateSyncSeriesProperties:(id)viewer :(SyncSeriesState) syncState :(SyncSeriesScope) syncScope :(SyncSeriesBehavior) syncBehavior;
+ (void) positionChange:(id) viewer :(NSArray*) relativePositionChange;

+ (void) syncSeriesNotification:(id)viewer :(NSNotification*)notification;
+ (void) posChangeNotification:(id)viewer :(NSNotification*)notification;

+ (void) synchronizeViewer:(id)currentViewer;
+ (void) synchronizeViewersPosition:(id) onlyViewerToBeSynchronized;
+ (void) validateViewersSyncSeriesState;

+ (void) initSyncSeriesToolbarItem:(id)viewer :(KBPopUpToolbarItem *) toolbarItem;
+ (void) updateSyncSeriesToolbarItemUI:(id)viewer;
+ (void) evaluteSyncSeriesToolbarItemActivationWhenInit:(id)currentViewer;
+ (void) evaluteSyncSeriesToolbarItemActivationBeforeClose:(id)currentViewer;
+ (BOOL) getSyncSeriesToolbarItemActivation;

+ (NSMutableArray*) MPRViewersWithout:(id) currentViewer;
+ (NSMutableArray*) MPRViewersWithout:(id)currentViewer andSyncEnabled:(BOOL)syncEnabledOnly;
+ (bool) isMPRViewer:(id) viewer;

// Thick Slab
-(IBAction) setThickSlabMode : (id) sender;
-(IBAction) setThickSlab : (id) sender;
-(IBAction) activateThickSlab : (id) sender;

// NSSplitView Control
- (void) adjustSplitView;
//- (void) turnSplitView;
- (void) updateToolbarItems;

// Tools Selection
- (IBAction) resetImage:(id) sender;
- (IBAction) changeTool:(id) sender;

// NSToolbar Related Methods
- (void) setupToolbar;
- (IBAction) customizeViewerToolBar:(id)sender;
- (NSToolbarItem *) toolbar: (NSToolbar *)toolbar itemForItemIdentifier: (NSString *) itemIdent willBeInsertedIntoToolbar:(BOOL) willBeInserted;
- (NSArray *) toolbarDefaultItemIdentifiers: (NSToolbar *) toolbar;
- (NSArray *) toolbarAllowedItemIdentifiers: (NSToolbar *) toolbar;
- (void) toolbarWillAddItem: (NSNotification *) notif;
- (void) toolbarDidRemoveItem: (NSNotification *) notif;
- (BOOL) validateToolbarItem: (NSToolbarItem *) toolbarItem;
- (void) fullWindowView:(int)index;

- (void) blendingPropagateOriginal:(OrthogonalMPRView*) sender;
- (void) blendingPropagateX:(OrthogonalMPRView*) sender;
- (void) blendingPropagateY:(OrthogonalMPRView*) sender;

-(void) ApplyOpacityString:(NSString*) str;

//export

-(IBAction) changeFromAndToBounds:(id) sender;
-(IBAction) setCurrentPosition:(id) sender;
-(IBAction) setCurrentdcmExport:(id) sender;

-(void) checkView:(NSView *)aView :(BOOL) OnOff;

-(void) dcmExportTextFieldDidChange:(NSNotification *)note;

// ROIs
- (IBAction) roiDeleteAll:(id) sender;

// 4D
- (void) MoviePlayStop:(id) sender;
- (void) setMovieIndex: (short) i;
- (void) movieRateSliderAction:(id) sender;
- (void) moviePosSliderAction:(id) sender;

- (ViewerController *)viewerController;
- (void)setCurrentTool:(ToolMode)currentTool;

- (void)bringToFrontROI:(ROI*)roi;
- (void)setMode:(long)mode toROIGroupWithID:(NSTimeInterval)groupID;
- (IBAction) endExportDICOMFileSettings:(id) sender;
- (void) exportDICOMFile:(id) sender;
@end
