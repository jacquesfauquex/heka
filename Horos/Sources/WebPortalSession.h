
#import <Cocoa/Cocoa.h>

extern NSString* const SessionUsernameKey; // NSString
extern NSString* const SessionCookieName;
extern NSString* const SessionLastActivityDateKey; // NSDate
extern NSString* const SessionUserIDKey;

@interface WebPortalSession : NSObject {
@private
	NSMutableDictionary* dict;
	NSString* sid;
	NSLock* dictLock;
}

@property(readonly) NSString* sid;
@property(readonly) NSMutableDictionary* dict;

-(id)initWithId:(NSString*)isid;

-(void)setObject:(id)o forKey:(NSString*)k;
-(id)objectForKey:(NSString*)k;

-(NSString*)createToken;
-(BOOL)consumeToken:(NSString*)token;
-(BOOL)containsToken:(NSString*)token;
-(NSString*)newChallenge;
-(NSString*)challenge;
-(void)deleteChallenge;

@end

