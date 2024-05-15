


#import <Foundation/Foundation.h>
#import <Carbon/Carbon.h>

/** \brief Import into Photos*/
@interface Photos : NSObject
{
}

- (void)runScript:(NSString *)txt;
- (BOOL)importInPhotos: (NSArray*) files;
@end
