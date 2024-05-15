
#import <dicomData.h>

@implementation dicomData

-(id) init
{
	self = [super init];
	
	group = Nil;
	name = Nil;
	tagName = Nil;
	content = Nil;
	parent = Nil;
	child = Nil;
	parentData = Nil;
	
	return self;
}

- (dicomData*) parentData
{
	return parentData;
}

- (void) setParentData:(dicomData*) p
{
	parentData = p;
}

- (NSMutableArray*) parent
{
    return parent;
}

- (void) setParent:(NSMutableArray*) p
{
    parent = p;
}

- (NSMutableArray*) child
{
    return child;
}

- (void) setChild:(NSMutableArray*) p
{
    child = p;
}

- (NSString*) group
{
    return group;
}

- (void) setGroup:(NSString *) s
{
    [s retain];
    [group release];
    group = s;
}

- (NSString*) name
{
    return name;
}

- (void) setName:(NSString *) s
{
    [s retain];
    [name release];
    name = s;
}

- (NSString*) tagName
{
    return tagName;
}

- (void) setTagName:(NSString *) s
{
    [s retain];
    [tagName release];
    tagName = s;
}

- (NSString*) content
{
    return content;
}

- (void) setContent:(NSString *) s
{
    [s retain];
    [content release];
    content = s;
}
@end
