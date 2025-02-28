#import "NSUserDefaults+OsiriX.h"
#import "N2Shell.h"
#import <Foundation/Foundation.h>
#import "BrowserController.h"
#import "NSScreen+N2.h"


@implementation NSUserDefaults (OsiriX)

#pragma mark General

NSString* const OsirixDateTimeFormatDefaultsKey = @"DBDateFormat2";

+(NSString*)dateTimeFormat {
	NSString* r = [NSUserDefaultsController.sharedUserDefaultsController stringForKey:OsirixDateTimeFormatDefaultsKey];
	if (!r) r = [[[[NSDateFormatter alloc] init] autorelease] dateFormat];
	return r;
}

+(NSDateFormatter*)dateTimeFormatter {
	static NSDateFormatter* formatter = NULL;
	if (!formatter)
		formatter = [[NSDateFormatter alloc] init];
	
	if (![formatter.dateFormat isEqual:[self dateTimeFormat]])
		formatter.dateFormat = [self dateTimeFormat];
	
	return formatter;
}

+(NSString*)formatDateTime:(NSDate*)date {
	return [self.dateTimeFormatter stringFromDate:date];
}

NSString* const OsirixDateFormatDefaultsKey = @"DBDateOfBirthFormat2";

+(NSString*)dateFormat {
	NSString* r = [NSUserDefaultsController.sharedUserDefaultsController stringForKey:OsirixDateFormatDefaultsKey];
	if (!r) r = [[[[NSDateFormatter alloc] init] autorelease] dateFormat];
	return r;
}

+(NSDateFormatter*)dateFormatter {
	static NSDateFormatter* formatter = NULL;
	if (!formatter)
		formatter = [[NSDateFormatter alloc] init];
	
	if (![formatter.dateFormat isEqual: [self dateFormat]])
		formatter.dateFormat = [self dateFormat];
	
	return formatter;
}

+(NSString*)formatDate:(NSDate*)date {
	return [self.dateFormatter stringFromDate:date];
}

NSString* const OsirixCanActivateDefaultDatabaseOnlyDefaultsKey = @"addNewIncomingFilesToDefaultDBOnly";

+(BOOL)canActivateOnlyDefaultDatabase {
	return [self.standardUserDefaults boolForKey:OsirixCanActivateDefaultDatabaseOnlyDefaultsKey];
}

+(BOOL)canActivateAnyLocalDatabase {
	return !self.canActivateOnlyDefaultDatabase;
}

#ifdef OSIRIX_VIEWER

NSString* const O2NonViewerScreensDefaultsKey = @"NonViewerScreens";

-(NSArray*)screensNotUsedForViewers {
    NSArray* nonIDs = [self arrayForKey:O2NonViewerScreensDefaultsKey];
    
    if (!nonIDs) { // the array doesn't exist, consider the ReserveScreenForDB default
        NSMutableArray* mnonIDs = [NSMutableArray array];
        
        switch ([self integerForKey:@"ReserveScreenForDB"]) {
            case 0: // all screens are used, the exclusion list is empty
                break;
            case 1: // all except DB, all screens are used but the tiling algorithm must consider the ReserveScreenForDB default and exclude the screen where the database currently is
                break;
            case 2: // main screen only
                for (NSScreen* screen in [NSScreen screens])
                    if (screen != [NSScreen mainScreen])
                        [mnonIDs addObject:[NSNumber numberWithUnsignedInteger:[screen screenNumber]]];
                [self setInteger:0 forKey:@"ReserveScreenForDB"];
                break;
        }
        
        [self setObject:mnonIDs forKey:O2NonViewerScreensDefaultsKey];
        
        nonIDs = mnonIDs;
    }
    
    NSMutableArray* screens = [[[NSScreen screens] mutableCopy] autorelease];
    for (NSInteger i = (long)screens.count-1; i >= 0; --i) {
        NSScreen* screen = [screens objectAtIndex:i];
        if (![nonIDs containsObject:[NSNumber numberWithUnsignedInteger:[screen screenNumber]]])
            [screens removeObjectAtIndex:i];
    }
    
    return screens;
}

-(NSArray*)screensUsedForViewers {
    NSMutableArray* screens = [[[NSScreen screens] mutableCopy] autorelease];
    for (NSScreen* screen in [self screensNotUsedForViewers])
        [screens removeObject:screen];
    return screens;
}

-(BOOL)screenIsUsedForViewers:(NSScreen*)screen {
    return [[self screensUsedForViewers] containsObject:screen];
}

-(void)screen:(NSScreen*)screen setIsUsedForViewers:(BOOL)flag {
    NSMutableArray* a = [[[self arrayForKey:O2NonViewerScreensDefaultsKey] mutableCopy] autorelease];
    if (!a) a = [NSMutableArray array];

    if (!flag && [self screenIsUsedForViewers:screen])
        [a addObject:[NSNumber numberWithUnsignedInteger:screen.screenNumber]];
    if (flag && ![self screenIsUsedForViewers:screen])
        [a removeObject:[NSNumber numberWithUnsignedInteger:screen.screenNumber]];

    [self setObject:a forKey:O2NonViewerScreensDefaultsKey];
}


#endif

#pragma mark Web Portal

NSString* const OsirixWebPortalEnabledDefaultsKey = @"httpWebServer";
+(BOOL)webPortalEnabled {
	#ifdef OSIRIX_LIGHT
	return NO;
	#else
	return [NSUserDefaultsController.sharedUserDefaultsController boolForKey:OsirixWebPortalEnabledDefaultsKey];
	#endif
}

NSString* const OsirixWebPortalAddressDefaultsKey = @"webServerAddress";
+(NSString*)webPortalAddress {
	NSString* r = [NSUserDefaultsController.sharedUserDefaultsController stringForKey:OsirixWebPortalAddressDefaultsKey];
	if (!r.length) r = self.defaultWebPortalAddress;
	return r;
}
+(NSString*)defaultWebPortalAddress {
	return N2Shell.hostname;
}

NSString* const OsirixWebPortalPortNumberDefaultsKey = @"httpWebServerPort";
+(NSInteger)webPortalPortNumber {
	NSInteger r = [NSUserDefaultsController.sharedUserDefaultsController integerForKey:OsirixWebPortalPortNumberDefaultsKey];
	if (!r) r = self.defaultWebPortalPortNumber;
	return r;
}
+(NSInteger)defaultWebPortalPortNumber {
	return 3333;
}

NSString* const OsirixWebPortalUsesSSLDefaultsKey = @"encryptedWebServer";
+(BOOL)webPortalUsesSSL {
	return [NSUserDefaultsController.sharedUserDefaultsController boolForKey:OsirixWebPortalUsesSSLDefaultsKey];
}

NSString* const OsirixWebPortalUsesWeasisDefaultsKey = @"WebServerUsesWeasis";
+(BOOL)webPortalUsesWeasis {
	return [NSUserDefaultsController.sharedUserDefaultsController boolForKey:OsirixWebPortalUsesWeasisDefaultsKey];
}

NSString* const OsirixWadoServiceEnabledDefaultsKey = @"wadoServer";
+(BOOL)wadoServiceEnabled {
	return [NSUserDefaultsController.sharedUserDefaultsController boolForKey:OsirixWadoServiceEnabledDefaultsKey];
}

NSString* const OsirixWebPortalPrefersFlashDefaultsKey = @"WebServerPrefersFlash";

+(BOOL)webPortalPrefersFlash {
	return [NSUserDefaultsController.sharedUserDefaultsController boolForKey:OsirixWebPortalPrefersFlashDefaultsKey];
}

NSString* const OsirixWebPortalPrefersCustomWebPagesKey = @"customWebPages";
+(BOOL)webPortalPrefersCustomWebPages {
	return [NSUserDefaultsController.sharedUserDefaultsController boolForKey:OsirixWebPortalPrefersCustomWebPagesKey];
}

NSString* const OsirixWebPortalNotificationsEnabledDefaultsKey = @"notificationsEmails";
+(BOOL)webPortalNotificationsEnabled {
	return [NSUserDefaultsController.sharedUserDefaultsController boolForKey:OsirixWebPortalNotificationsEnabledDefaultsKey];
}

NSString* const OsirixWebPortalNotificationsIntervalDefaultsKey = @"notificationsEmailsInterval";
+(NSInteger)webPortalNotificationsInterval {
	return [NSUserDefaultsController.sharedUserDefaultsController integerForKey:OsirixWebPortalNotificationsIntervalDefaultsKey];
}

NSString* const OsirixWebPortalRequiresAuthenticationDefaultsKey = @"passwordWebServer";
+(BOOL)webPortalRequiresAuthentication {
	return [NSUserDefaultsController.sharedUserDefaultsController boolForKey:OsirixWebPortalRequiresAuthenticationDefaultsKey];
}

NSString* const OsirixWebPortalUsersCanRestorePasswordDefaultsKey = @"restorePasswordWebServer";
+(BOOL)webPortalUsersCanRestorePassword {
	return [NSUserDefaultsController.sharedUserDefaultsController boolForKey:OsirixWebPortalUsersCanRestorePasswordDefaultsKey];
}

// MARK: DICOM Communications

+ (NSString*)defaultAETitle;
{
	if ([[NSUserDefaults standardUserDefaults] boolForKey:@"STORESCPTLS"])
	{
		if ([[NSUserDefaults standardUserDefaults] boolForKey:@"STORESCP"]
			&& ![[NSUserDefaults standardUserDefaults] boolForKey:@"TLSStoreSCPAETITLEIsDefaultAET"])
		{
			return [[NSUserDefaults standardUserDefaults] stringForKey:@"AETITLE"];
		}
		return [[NSUserDefaults standardUserDefaults] stringForKey:@"TLSStoreSCPAETITLE"];
	}
	return [[NSUserDefaults standardUserDefaults] stringForKey:@"AETITLE"];
}

+ (int)defaultAEPort;
{
	if ([[NSUserDefaults standardUserDefaults] boolForKey:@"STORESCPTLS"])
	{
		if ([[NSUserDefaults standardUserDefaults] boolForKey:@"STORESCP"]
			&& ![[NSUserDefaults standardUserDefaults] boolForKey:@"TLSStoreSCPAETITLEIsDefaultAET"])
		{
			return [[[NSUserDefaults standardUserDefaults] stringForKey:@"AEPORT"] intValue];
		}
		return [[[NSUserDefaults standardUserDefaults] stringForKey:@"TLSStoreSCPAEPORT"] intValue];
	}
	return [[[NSUserDefaults standardUserDefaults] stringForKey:@"AEPORT"] intValue];
}

@end
