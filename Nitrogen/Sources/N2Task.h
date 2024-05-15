#import <Cocoa/Cocoa.h>
#include <sys/event.h>

NS_ASSUME_NONNULL_BEGIN

@interface N2Task : NSTask {
	NSString* _launchPath;
	NSArray* _arguments;
	pid_t _pid;
	uid_t _uid;
	NSTimeInterval _launchTime;
	NSDictionary* _environment;
	NSString* _currentDirectoryPath;
	id _standardError, _standardInput, _standardOutput;
}

@property (nullable, copy) NSArray<NSString *> *arguments;
@property (copy) NSString* currentDirectoryPath;
@property (nullable, copy) NSDictionary<NSString *, NSString *> *environment;
@property (nullable, copy) NSString *launchPath;
@property (nullable, retain) id standardError;
@property (nullable, retain) id standardInput;
@property (nullable, retain) id standardOutput;

@property (readonly) NSTimeInterval launchTime;
@property (assign) uid_t uid;


//-(void)setEnv:(NSString*)name to:(NSString*)value;

@end

NS_ASSUME_NONNULL_END
