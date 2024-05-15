

#import <Foundation/Foundation.h>


/** \brief Tree node for xml */
@interface dicomData: NSObject {
    NSString        *group;
    NSString        *name;
    NSString        *tagName;
    NSString        *content;
    
    NSMutableArray  *parent;
    NSMutableArray  *child;
	dicomData		*parentData;
}

- (dicomData*) parentData;
- (void) setParentData:(dicomData*) p;

- (NSMutableArray*) parent;
- (void) setParent:(NSMutableArray*) p;

- (NSMutableArray*) child;
- (void) setChild:(NSMutableArray*) p;

- (NSString*) group;
- (void) setGroup:(NSString *) s;

- (NSString*) name;
- (void) setName:(NSString *) s;

- (NSString*) tagName;
- (void) setTagName:(NSString *) s;

- (NSString*) content;
- (void) setContent:(NSString *) s;

@end
