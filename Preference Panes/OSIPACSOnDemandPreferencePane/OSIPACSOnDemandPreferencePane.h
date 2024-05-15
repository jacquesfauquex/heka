#import <PreferencePanes/PreferencePanes.h>
#import "sourcesTableView.h"

@interface OSIPACSOnDemandPreferencePane : NSPreferencePane 
{

	IBOutlet NSWindow *mainWindow;
    
    NSMutableArray *sourcesArray;
    IBOutlet sourcesTableView *sourcesTable;
    
    NSMutableArray *smartAlbumsArray;
    IBOutlet NSTableView *smartAlbumsTable;
    
    NSArray *albumDBArray;
    
    IBOutlet NSWindow *smartAlbumsEditWindow;
    IBOutlet NSMatrix *dateMatrix;
    NSMutableArray *smartAlbumModality;
    NSString *smartAlbumFilter;
    int smartAlbumDate;
    
    id _tlos;
}

@property (retain) NSMutableArray *smartAlbumsArray, *smartAlbumModality;
@property (retain) NSString *smartAlbumFilter;
@property int smartAlbumDate;

- (void) mainViewDidLoad;
@end
